import 'dart:convert';
import 'dart:typed_data';

final _bn254P = BigInt.parse(
  '30644E72E131A029B85045B68181585D97816A916871CA8D3C208C16D87CFD47',
  radix: 16,
);
final _bn254R = BigInt.parse(
  '30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001',
  radix: 16,
);

class Groth16Bundle {
  const Groth16Bundle({
    required this.verificationKeyBase64,
    required this.proofBase64,
    required this.inputsBase64,
    required this.nPublic,
  });

  final String verificationKeyBase64;
  final String proofBase64;
  final String inputsBase64;
  final int nPublic;

  Map<String, dynamic> toJson() => {
    'vk_b64': verificationKeyBase64,
    'proof_b64': proofBase64,
    'inputs_b64': inputsBase64,
    'n_public': nPublic,
  };
}

Groth16Bundle encodeGroth16Bundle({
  required String verificationKeyJson,
  required String proofJson,
  required String publicJson,
}) {
  final vk = jsonDecode(verificationKeyJson) as Map<String, dynamic>;
  final proof = jsonDecode(proofJson) as Map<String, dynamic>;
  final publicInputs = jsonDecode(publicJson);
  if (publicInputs is! List) {
    throw const FormatException('public.json must be a JSON array');
  }

  _ensureIn(vk['curve'], const ['bn128', null], 'curve');
  _ensureIn(vk['protocol'], const ['groth16', null], 'vk.protocol');
  _ensureIn(proof['protocol'], const ['groth16', null], 'proof.protocol');

  final nPublic = _toInt(vk['nPublic'], 'nPublic');
  if (nPublic < 0 || nPublic > 1024) {
    throw const FormatException('nPublic must be between 0 and 1024');
  }
  if (publicInputs.length != nPublic) {
    throw FormatException(
      'public input count mismatch: vk.nPublic=$nPublic public.json=${publicInputs.length}',
    );
  }

  final ic = _list(vk['IC'], 'IC');
  if (ic.length != nPublic + 1) {
    throw FormatException('IC length must be nPublic + 1 (${nPublic + 1})');
  }

  final vkBytes = BytesBuilder()
    ..add(ascii.encode('OG16V1'))
    ..add(_u32(nPublic))
    ..add(_g1(_list(vk['vk_alpha_1'], 'vk_alpha_1'), 'vk_alpha_1'))
    ..add(_g2(_list(vk['vk_beta_2'], 'vk_beta_2'), 'vk_beta_2'))
    ..add(_g2(_list(vk['vk_gamma_2'], 'vk_gamma_2'), 'vk_gamma_2'))
    ..add(_g2(_list(vk['vk_delta_2'], 'vk_delta_2'), 'vk_delta_2'));
  for (var i = 0; i < ic.length; i++) {
    vkBytes.add(_g1(_list(ic[i], 'IC[$i]'), 'IC[$i]'));
  }

  final proofBytes = BytesBuilder()
    ..add(ascii.encode('OG16P1'))
    ..add(_g1(_list(proof['pi_a'], 'pi_a'), 'pi_a'))
    ..add(_g2(_list(proof['pi_b'], 'pi_b'), 'pi_b'))
    ..add(_g1(_list(proof['pi_c'], 'pi_c'), 'pi_c'));

  final inputBytes = BytesBuilder();
  for (var i = 0; i < publicInputs.length; i++) {
    inputBytes.add(_field(publicInputs[i], _bn254R, 'input[$i]'));
  }

  return Groth16Bundle(
    verificationKeyBase64: base64Encode(vkBytes.toBytes()),
    proofBase64: base64Encode(proofBytes.toBytes()),
    inputsBase64: base64Encode(inputBytes.toBytes()),
    nPublic: nPublic,
  );
}

Uint8List _g1(List<dynamic> point, String label) {
  if (point.length < 2) {
    throw FormatException('$label expected [x, y] or [x, y, z]');
  }
  if (point.length >= 3 && point[2].toString() != '1') {
    throw FormatException('$label.z must be 1');
  }
  final x = _field(point[0], _bn254P, '$label.x');
  final y = _field(point[1], _bn254P, '$label.y');
  if (_isZero(point[0]) && _isZero(point[1])) {
    throw FormatException('$label cannot be point at infinity');
  }
  return Uint8List.fromList([...x, ...y]);
}

Uint8List _g2(List<dynamic> point, String label) {
  if (point.length < 2) {
    throw FormatException('$label expected [x, y] or [x, y, z]');
  }
  final x = _fp2(_list(point[0], '$label.x'), '$label.x');
  final y = _fp2(_list(point[1], '$label.y'), '$label.y');
  return Uint8List.fromList([...x, ...y]);
}

Uint8List _fp2(List<dynamic> point, String label) {
  if (point.length < 2) {
    throw FormatException('$label expected [c0, c1]');
  }
  return Uint8List.fromList([
    ..._field(point[0], _bn254P, '$label.c0'),
    ..._field(point[1], _bn254P, '$label.c1'),
  ]);
}

Uint8List _field(dynamic value, BigInt modulus, String label) {
  final n = BigInt.parse(value.toString());
  if (n < BigInt.zero || n >= modulus) {
    throw FormatException('$label is outside field range');
  }
  final out = Uint8List(32);
  var v = n;
  for (var i = 31; i >= 0; i--) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v >>= 8;
  }
  return out;
}

Uint8List _u32(int value) {
  final out = Uint8List(4);
  ByteData.view(out.buffer).setUint32(0, value, Endian.big);
  return out;
}

List<dynamic> _list(dynamic value, String label) {
  if (value is List) return value;
  throw FormatException('$label must be an array');
}

int _toInt(dynamic value, String label) {
  final parsed = int.tryParse(value.toString());
  if (parsed == null) throw FormatException('$label must be an integer');
  return parsed;
}

bool _isZero(dynamic value) => BigInt.tryParse(value.toString()) == BigInt.zero;

void _ensureIn(dynamic value, List<Object?> allowed, String label) {
  if (!allowed.contains(value)) {
    throw FormatException('$label is not supported: $value');
  }
}
