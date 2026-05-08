import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

const _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
const _hardened = 0x80000000;
const _seedKey = 'Octra seed';

class DevWallet {
  const DevWallet({
    required this.address,
    required this.publicKeyBase64,
    this.privateKeyBase64,
    this.mnemonic,
    this.watchOnly = false,
  });

  final String address;
  final String publicKeyBase64;
  final String? privateKeyBase64;
  final String? mnemonic;
  final bool watchOnly;

  bool get canSign => !watchOnly && privateKeyBase64 != null;
}

class _Keys {
  const _Keys(this.privateKey, this.chainCode);

  final Uint8List privateKey;
  final Uint8List chainCode;
}

Future<DevWallet> importWallet(String rawInput) async {
  final input = rawInput.trim();
  if (input.isEmpty) {
    throw const FormatException('wallet input is empty');
  }

  if (input.startsWith('oct') && !input.contains(' ')) {
    return DevWallet(address: input, publicKeyBase64: '', watchOnly: true);
  }

  String? mnemonic;
  late Uint8List privateKeyBytes;
  final normalized = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  if (normalized.split(' ').length >= 12) {
    if (!bip39.validateMnemonic(normalized)) {
      throw const FormatException('invalid seed phrase');
    }
    mnemonic = normalized;
    privateKeyBytes = await derivePrivateKeyFromMnemonic(normalized);
  } else {
    privateKeyBytes = _decodePrivateKey(input);
  }

  if (privateKeyBytes.length != 32) {
    throw const FormatException('private key must be 32 bytes');
  }

  final keyPair = await Ed25519().newKeyPairFromSeed(privateKeyBytes);
  final publicKey = await keyPair.extractPublicKey();
  final address = await octraAddressFromPublicKey(publicKey.bytes);

  return DevWallet(
    address: address,
    privateKeyBase64: base64Encode(privateKeyBytes),
    publicKeyBase64: base64Encode(publicKey.bytes),
    mnemonic: mnemonic,
  );
}

Future<Uint8List> derivePrivateKeyFromMnemonic(String mnemonic) async {
  final seed = bip39.mnemonicToSeed(mnemonic);
  return deriveForNetwork(Uint8List.fromList(seed));
}

Future<Uint8List> deriveForNetwork(
  Uint8List seed, {
  int networkType = 0,
  int network = 0,
  int contract = 0,
  int account = 0,
  int index = 0,
  int token = 0,
  int subnet = 0,
}) async {
  final coinType = networkType == 0 ? 0 : networkType;
  final fullPath = [
    _hardened + 345,
    _hardened + coinType,
    _hardened + network,
    _hardened + contract,
    _hardened + account,
    _hardened + token,
    _hardened + subnet,
    index,
  ];

  var keys = _deriveMasterKey(seed);
  for (final pathPart in fullPath) {
    keys = await _deriveChildKeyEd25519(keys, pathPart);
  }
  return keys.privateKey;
}

Future<Map<String, dynamic>> signTransaction(
  DevWallet wallet,
  Map<String, dynamic> payload,
) async {
  if (!wallet.canSign) {
    throw StateError('watch-only wallet cannot sign transactions');
  }
  final signature = await signMessageBase64(wallet, canonicalTxJson(payload));
  final signed = Map<String, dynamic>.from(payload);
  signed['signature'] = signature;
  signed['public_key'] = wallet.publicKeyBase64;
  return signed;
}

Future<String> signMessageBase64(DevWallet wallet, String message) async {
  if (wallet.privateKeyBase64 == null) {
    throw StateError('private key is not available');
  }
  final privateKey = base64Decode(wallet.privateKeyBase64!);
  final keyPair = await Ed25519().newKeyPairFromSeed(privateKey);
  final signature = await Ed25519().sign(
    utf8.encode(message),
    keyPair: keyPair,
  );
  return base64Encode(signature.bytes);
}

String canonicalTxJson(Map<String, dynamic> tx) {
  final buffer = StringBuffer();
  buffer.write('{"from":${jsonEncode(tx["from"])}');
  buffer.write(',"to_":${jsonEncode(tx["to_"])}');
  buffer.write(',"amount":${jsonEncode(tx["amount"].toString())}');
  buffer.write(',"nonce":${tx["nonce"]}');
  buffer.write(',"ou":${jsonEncode(tx["ou"].toString())}');
  buffer.write(',"timestamp":${jsonEncode(tx["timestamp"])}');
  buffer.write(
    ',"op_type":${jsonEncode((tx["op_type"] ?? "standard").toString())}',
  );
  final encryptedData = tx['encrypted_data']?.toString() ?? '';
  if (encryptedData.isNotEmpty) {
    buffer.write(',"encrypted_data":${jsonEncode(encryptedData)}');
  }
  final message = tx['message']?.toString() ?? '';
  if (message.isNotEmpty) {
    buffer.write(',"message":${jsonEncode(message)}');
  }
  buffer.write('}');
  return buffer.toString();
}

Future<String> octraAddressFromPublicKey(List<int> publicKey) async {
  final hash = await Sha256().hash(publicKey);
  return 'oct${_base58(Uint8List.fromList(hash.bytes))}';
}

_Keys _deriveMasterKey(Uint8List seed) {
  final hmac = crypto.Hmac(crypto.sha512, utf8.encode(_seedKey));
  final bytes = hmac.convert(seed).bytes;
  return _Keys(
    Uint8List.fromList(bytes.sublist(0, 32)),
    Uint8List.fromList(bytes.sublist(32, 64)),
  );
}

Future<_Keys> _deriveChildKeyEd25519(_Keys parent, int index) async {
  final indexBytes = Uint8List(4);
  ByteData.view(indexBytes.buffer).setUint32(0, index, Endian.big);

  late Uint8List data;
  if ((index & _hardened) != 0) {
    data = Uint8List.fromList([0x00, ...parent.privateKey, ...indexBytes]);
  } else {
    final keyPair = await Ed25519().newKeyPairFromSeed(parent.privateKey);
    final publicKey = await keyPair.extractPublicKey();
    data = Uint8List.fromList([...publicKey.bytes, ...indexBytes]);
  }

  final hmac = crypto.Hmac(crypto.sha512, parent.chainCode);
  final bytes = hmac.convert(data).bytes;
  return _Keys(
    Uint8List.fromList(bytes.sublist(0, 32)),
    Uint8List.fromList(bytes.sublist(32, 64)),
  );
}

Uint8List _decodePrivateKey(String input) {
  final normalized = input.trim();
  if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized)) {
    return Uint8List.fromList([
      for (var i = 0; i < normalized.length; i += 2)
        int.parse(normalized.substring(i, i + 2), radix: 16),
    ]);
  }
  return Uint8List.fromList(base64Decode(normalized));
}

String _base58(Uint8List bytes) {
  var n = BigInt.parse(
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
  var result = '';
  while (n > BigInt.zero) {
    final mod = n % BigInt.from(58);
    result = _base58Alphabet[mod.toInt()] + result;
    n ~/= BigInt.from(58);
  }
  return result;
}
