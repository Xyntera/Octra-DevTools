import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'groth16_codec.dart';
import 'octra_crypto.dart';

void main() {
  runApp(const OctraDevToolsApp());
}

const _defaultRpcUrl = 'https://octra.network/rpc';
const _octScale = 1000000;

const _starterAml = '''program MobileCounter {
  state {
    owner: address
    count: int
  }

  event Incremented(by: address, value: int)

  constructor() {
    self.owner = caller
    self.count = 0
  }

  view fn get_count(): int {
    return self.count
  }

  fn increment(): bool {
    self.count = self.count + 1
    emit Incremented(caller, self.count)
    return true
  }
}
''';

class OctraDevToolsApp extends StatelessWidget {
  const OctraDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Octra DevTools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff07100d),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffb8f28b),
          secondary: Color(0xff66e0ff),
          surface: Color(0xff101b16),
          error: Color(0xffff7777),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Georgia',
          bodyColor: const Color(0xffedf8e8),
          displayColor: const Color(0xffedf8e8),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xaa08110d),
        ),
        useMaterial3: true,
      ),
      home: const DevToolsHome(),
    );
  }
}

class DevToolsHome extends StatefulWidget {
  const DevToolsHome({super.key});

  @override
  State<DevToolsHome> createState() => _DevToolsHomeState();
}

class _DevToolsHomeState extends State<DevToolsHome> {
  final _rpc = OctraRpcClient();
  final _rpcUrl = TextEditingController(text: _defaultRpcUrl);
  final _walletInput = TextEditingController();
  final _amlSource = TextEditingController(text: _starterAml);
  final _projectFiles = TextEditingController(
    text: const JsonEncoder.withIndent('  ').convert([
      {'path': 'main.aml', 'source': _starterAml},
    ]),
  );
  final _assemblySource = TextEditingController(
    text: '; Octra Assembly source',
  );
  final _bytecode = TextEditingController();
  final _deployParams = TextEditingController(text: '[]');
  final _deployFee = TextEditingController(text: '50000000');
  final _callAddress = TextEditingController();
  final _callMethod = TextEditingController(text: 'get_count');
  final _callParams = TextEditingController(text: '[]');
  final _callAmount = TextEditingController(text: '0');
  final _callFee = TextEditingController(text: '1000');
  final _infoAddress = TextEditingController();
  final _storageKey = TextEditingController(text: 'owner');
  final _verifyAddress = TextEditingController();
  final _feeOp = TextEditingController(text: 'deploy');
  final _vkJson = TextEditingController();
  final _proofJson = TextEditingController();
  final _publicJson = TextEditingController();
  final _proofContract = TextEditingController(
    text: 'oct3rzJZucw9BsS7LRWBNoKRoaBsXAhhSK4LmfRvg45ppSs',
  );
  final _proofCaller = TextEditingController();
  final _fheValue = TextEditingController(text: '42');
  final _fheCipher = TextEditingController();

  DevWallet? _wallet;
  String _output =
      'Ready. Import a wallet or use watch-only mode, then compile AML.';
  String _activeTask = 'Idle';
  bool _busy = false;

  @override
  void dispose() {
    _rpc.close();
    for (final c in [
      _rpcUrl,
      _walletInput,
      _amlSource,
      _projectFiles,
      _assemblySource,
      _bytecode,
      _deployParams,
      _deployFee,
      _callAddress,
      _callMethod,
      _callParams,
      _callAmount,
      _callFee,
      _infoAddress,
      _storageKey,
      _verifyAddress,
      _feeOp,
      _vkJson,
      _proofJson,
      _publicJson,
      _proofContract,
      _proofCaller,
      _fheValue,
      _fheCipher,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(String label, Future<Object?> Function() task) async {
    setState(() {
      _busy = true;
      _activeTask = label;
      _output = 'Running $label ...';
    });
    try {
      final result = await task();
      if (!mounted) return;
      setState(() => _output = _pretty(result));
    } catch (error) {
      if (!mounted) return;
      setState(() => _output = 'ERROR: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeTask = 'Idle';
        });
      }
    }
  }

  Future<void> _login() async {
    await _run('wallet import', () async {
      final wallet = await importWallet(_walletInput.text);
      setState(() {
        _wallet = wallet;
        if (_proofCaller.text.trim().isEmpty) {
          _proofCaller.text = wallet.address;
        }
      });
      return {
        'address': wallet.address,
        'mode': wallet.watchOnly ? 'watch-only' : 'signing',
        'public_key_b64': wallet.publicKeyBase64,
        'can_sign': wallet.canSign,
      };
    });
  }

  Future<void> _compileAml() => _run('compile AML', () async {
    final result = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_compileAml',
      params: [_amlSource.text],
    );
    _captureCompileOutput(result);
    return result;
  });

  Future<void> _compileProject() => _run('compile project', () async {
    final files = jsonDecode(_projectFiles.text);
    if (files is! List) throw const FormatException('files must be an array');
    final result = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_compileAmlMulti',
      params: [files, 'main.aml'],
    );
    _captureCompileOutput(result);
    return result;
  });

  Future<void> _compileAssembly() => _run('compile assembly', () async {
    final result = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_compileAssembly',
      params: [_assemblySource.text],
    );
    _captureCompileOutput(result);
    return result;
  });

  Future<void> _recommendedFee([String? op]) =>
      _run('recommended fee', () async {
        final opType = op ?? _feeOp.text.trim();
        final result = await _rpc.call(
          url: _rpcUrl.text,
          method: 'octra_recommendedFee',
          params: opType.isEmpty ? [] : [opType],
        );
        final fee = _extractFee(result);
        if (opType == 'deploy' && fee != null) _deployFee.text = fee;
        if (opType == 'call' && fee != null) _callFee.text = fee;
        return result;
      });

  Future<void> _previewDeploy() => _run('preview deploy address', () async {
    final wallet = _requireWallet();
    final bytecode = _bytecode.text.trim();
    if (bytecode.isEmpty) throw const FormatException('bytecode required');
    final nonce = await _nextNonce(wallet.address);
    return _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_computeContractAddress',
      params: [bytecode, wallet.address, nonce],
    );
  });

  Future<void> _deploy() => _run('deploy program', () async {
    final wallet = _requireSigningWallet();
    final bytecode = _bytecode.text.trim();
    if (bytecode.isEmpty) throw const FormatException('bytecode required');
    final params = _deployParams.text.trim();
    if (params.isNotEmpty) jsonDecode(params);
    final nonce = await _nextNonce(wallet.address);
    final addressResult = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_computeContractAddress',
      params: [bytecode, wallet.address, nonce],
    );
    final contractAddress = _map(addressResult)['address']?.toString() ?? '';
    if (contractAddress.isEmpty) {
      throw StateError('RPC did not return contract address');
    }
    final tx = {
      'from': wallet.address,
      'to_': contractAddress,
      'amount': '0',
      'nonce': nonce,
      'ou': _deployFee.text.trim().isEmpty
          ? '50000000'
          : _deployFee.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'op_type': 'deploy',
      'encrypted_data': bytecode,
      if (params.isNotEmpty && params != '[]') 'message': params,
    };
    final signed = await signTransaction(wallet, tx);
    final submit = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_submit',
      params: [signed],
      timeout: const Duration(seconds: 30),
    );
    _callAddress.text = contractAddress;
    _infoAddress.text = contractAddress;
    _verifyAddress.text = contractAddress;
    return {
      'contract_address': contractAddress,
      'signed_tx': signed,
      'submit': submit,
    };
  });

  Future<void> _viewCall() => _run('read-only contract call', () async {
    final params = _parseJsonArray(_callParams.text);
    final caller = _wallet?.address;
    return _rpc.call(
      url: _rpcUrl.text,
      method: 'contract_call',
      params: [
        _callAddress.text.trim(),
        _callMethod.text.trim(),
        params,
        caller ?? '',
      ],
      timeout: const Duration(seconds: 20),
    );
  });

  Future<void> _sendCall() => _run('send contract call tx', () async {
    final wallet = _requireSigningWallet();
    final params = _parseJsonArray(_callParams.text);
    final nonce = await _nextNonce(wallet.address);
    final tx = {
      'from': wallet.address,
      'to_': _callAddress.text.trim(),
      'amount': _octToRaw(_callAmount.text.trim()),
      'nonce': nonce,
      'ou': _callFee.text.trim().isEmpty ? '1000' : _callFee.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'op_type': 'call',
      'encrypted_data': _callMethod.text.trim(),
      'message': jsonEncode(params),
    };
    final signed = await signTransaction(wallet, tx);
    final submit = await _rpc.call(
      url: _rpcUrl.text,
      method: 'octra_submit',
      params: [signed],
      timeout: const Duration(seconds: 30),
    );
    return {'signed_tx': signed, 'submit': submit};
  });

  Future<void> _contractInfo() => _run('contract info', () async {
    final address = _infoAddress.text.trim();
    return {
      'contract': await _rpc.call(
        url: _rpcUrl.text,
        method: 'vm_contract',
        params: [address],
      ),
      'abi': await _rpc.call(
        url: _rpcUrl.text,
        method: 'octra_contractAbi',
        params: [address],
      ),
      if (_storageKey.text.trim().isNotEmpty)
        'storage.${_storageKey.text.trim()}': await _rpc.call(
          url: _rpcUrl.text,
          method: 'octra_contractStorage',
          params: [address, _storageKey.text.trim()],
        ),
    };
  });

  Future<void> _verifySource() => _run('verify source', () async {
    return _rpc.call(
      url: _rpcUrl.text,
      method: 'contract_verify',
      params: [_verifyAddress.text.trim(), _amlSource.text],
      timeout: const Duration(seconds: 30),
    );
  });

  Future<void> _proofEncodeAndVerify() =>
      _run('Groth16 BN254 proof verify', () async {
        final bundle = encodeGroth16Bundle(
          verificationKeyJson: _vkJson.text,
          proofJson: _proofJson.text,
          publicJson: _publicJson.text,
        );
        final caller = _proofCaller.text.trim().isNotEmpty
            ? _proofCaller.text.trim()
            : (_wallet?.address ?? _proofContract.text.trim());
        final verifyResult = await _rpc.call(
          url: _rpcUrl.text,
          method: 'contract_call',
          params: [
            _proofContract.text.trim(),
            'verify',
            [bundle.proofBase64, bundle.inputsBase64],
            caller,
          ],
          timeout: const Duration(seconds: 30),
        );
        return {'bundle': bundle.toJson(), 'verify_result': verifyResult};
      });

  Future<void> _fheNativeRequired(String mode) => _run('FHE $mode', () async {
    return {
      'status': 'native_pvac_required',
      'reason':
          'FHE $mode must use the PVAC native library through Flutter FFI. This screen is wired as the product surface, but it intentionally does not fake ciphertext generation.',
      'input_value': _fheValue.text,
      'ciphertext': _fheCipher.text,
    };
  });

  Future<int> _nextNonce(String address) async {
    final balance = _map(
      await _rpc.call(
        url: _rpcUrl.text,
        method: 'octra_balance',
        params: [address],
      ),
    );
    var nonce = int.tryParse(balance['nonce']?.toString() ?? '') ?? 0;
    try {
      final staging = _map(
        await _rpc.call(url: _rpcUrl.text, method: 'staging_view', params: []),
      );
      final staged = staging['staged_transactions'] ?? staging['transactions'];
      if (staged is List) {
        for (final item in staged.whereType<Map>()) {
          final from = item['from']?.toString();
          final txNonce = int.tryParse(item['nonce']?.toString() ?? '') ?? 0;
          if (from == address && txNonce > nonce) nonce = txNonce;
        }
      }
    } catch (_) {
      // Staging is optional for nonce calculation; confirmed nonce is enough to continue.
    }
    return nonce + 1;
  }

  void _captureCompileOutput(Object? result) {
    final map = _map(result);
    final bc = map['bytecode']?.toString();
    if (bc != null && bc.isNotEmpty) _bytecode.text = bc;
  }

  DevWallet _requireWallet() {
    final wallet = _wallet;
    if (wallet == null) {
      throw StateError('import wallet or watch-only address first');
    }
    return wallet;
  }

  DevWallet _requireSigningWallet() {
    final wallet = _requireWallet();
    if (!wallet.canSign) {
      throw StateError('private key or seed phrase required for signing');
    }
    return wallet;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Atmosphere(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  sliver: SliverToBoxAdapter(child: _header(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.crossAxisExtent >= 1100;
                      final left = Column(
                        children: [
                          _connectionCard(),
                          _compilerCard(),
                          _deployCard(),
                          _callCard(),
                        ],
                      );
                      final right = Column(
                        children: [
                          _inspectorCard(),
                          _verifyCard(),
                          _proofCard(),
                          _fheCard(),
                          _outputCard(),
                        ],
                      );
                      if (!wide) {
                        return SliverList.list(children: [left, right]);
                      }
                      return SliverToBoxAdapter(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 18),
                            Expanded(child: right),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return _Glass(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Native Octra IDE',
                  style: TextStyle(color: Color(0xffb8f28b)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Octra DevTools',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _wallet == null
                      ? 'Compile, inspect, deploy, call, verify, and test proofs from a native Flutter client.'
                      : 'Wallet: ${_wallet!.address} (${_wallet!.watchOnly ? 'watch-only' : 'signing'})',
                ),
              ],
            ),
          ),
          if (_busy)
            Column(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 8),
                Text(_activeTask),
              ],
            ),
        ],
      ),
    );
  }

  Widget _connectionCard() {
    return _Card(
      title: 'Wallet and RPC',
      subtitle: 'Private key, seed phrase, or watch-only address',
      children: [
        _field(_rpcUrl, 'RPC endpoint'),
        _field(
          _walletInput,
          'Seed phrase, 32-byte private key, or oct watch-only address',
          lines: 3,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _login,
              icon: const Icon(Icons.login),
              label: const Text('Import / Login'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _recommendedFee(),
              icon: const Icon(Icons.speed),
              label: const Text('Fetch Fee'),
            ),
          ],
        ),
        _field(
          _feeOp,
          'Fee operation type: standard, deploy, call, stealth, decrypt',
        ),
      ],
    );
  }

  Widget _compilerCard() {
    return _Card(
      title: 'Compiler',
      subtitle: 'AML, multi-file AML, and OASM through Octra RPC',
      children: [
        _field(_amlSource, 'main.aml', lines: 12, mono: true),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: _busy ? null : _compileAml,
              child: const Text('Compile AML'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _compileProject,
              child: const Text('Compile Project JSON'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _compileAssembly,
              child: const Text('Compile OASM'),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('Project files JSON'),
          children: [_field(_projectFiles, 'files', lines: 9, mono: true)],
        ),
        ExpansionTile(
          title: const Text('Assembly source'),
          children: [
            _field(_assemblySource, 'source.oasm', lines: 7, mono: true),
          ],
        ),
        _field(_bytecode, 'Compiled bytecode', lines: 3, mono: true),
      ],
    );
  }

  Widget _deployCard() {
    return _Card(
      title: 'Deploy Program',
      subtitle: 'Local signed deploy transaction using webcli tx shape',
      children: [
        _field(_deployParams, 'Constructor params JSON array'),
        _field(_deployFee, 'Deploy fee in ou'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : () => _recommendedFee('deploy'),
              child: const Text('Recommended Fee'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _previewDeploy,
              child: const Text('Preview Address'),
            ),
            FilledButton(
              onPressed: _busy ? null : _deploy,
              child: const Text('Sign and Deploy'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _callCard() {
    return _Card(
      title: 'Call Program',
      subtitle: 'Read-only view or signed state-changing call',
      children: [
        _field(_callAddress, 'Program address'),
        _field(_callMethod, 'Method name'),
        _field(_callParams, 'Params JSON array'),
        Row(
          children: [
            Expanded(child: _field(_callAmount, 'Attached OCT')),
            const SizedBox(width: 10),
            Expanded(child: _field(_callFee, 'Call fee in ou')),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : () => _recommendedFee('call'),
              child: const Text('Recommended Fee'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _viewCall,
              child: const Text('View Read-only'),
            ),
            FilledButton(
              onPressed: _busy ? null : _sendCall,
              child: const Text('Sign Call Tx'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inspectorCard() {
    return _Card(
      title: 'Contract Inspector',
      subtitle: 'Metadata, ABI, storage key',
      children: [
        _field(_infoAddress, 'Program address'),
        _field(_storageKey, 'Storage key'),
        FilledButton(
          onPressed: _busy ? null : _contractInfo,
          child: const Text('Lookup Contract'),
        ),
      ],
    );
  }

  Widget _verifyCard() {
    return _Card(
      title: 'Source Verification',
      subtitle: 'Verify current main.aml against deployed bytecode',
      children: [
        _field(_verifyAddress, 'Program address'),
        FilledButton(
          onPressed: _busy ? null : _verifySource,
          child: const Text('Verify Source'),
        ),
      ],
    );
  }

  Widget _proofCard() {
    return _Card(
      title: 'Groth16 BN254 Proof Lab',
      subtitle: 'snarkjs JSON encoder plus Octra verifier call',
      children: [
        _field(_proofContract, 'Verifier contract'),
        _field(_proofCaller, 'Caller address'),
        ExpansionTile(
          title: const Text('verification_key.json'),
          children: [_field(_vkJson, 'VK JSON', lines: 5, mono: true)],
        ),
        ExpansionTile(
          title: const Text('proof.json'),
          children: [_field(_proofJson, 'Proof JSON', lines: 5, mono: true)],
        ),
        ExpansionTile(
          title: const Text('public.json'),
          children: [
            _field(_publicJson, 'Public inputs JSON', lines: 3, mono: true),
          ],
        ),
        FilledButton(
          onPressed: _busy ? null : _proofEncodeAndVerify,
          child: const Text('Encode and Verify'),
        ),
      ],
    );
  }

  Widget _fheCard() {
    return _Card(
      title: 'FHE Tools',
      subtitle:
          'Product surface ready; native PVAC FFI required for real crypto',
      children: [
        _field(_fheValue, 'Integer value'),
        _field(_fheCipher, 'Ciphertext', lines: 3, mono: true),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : () => _fheNativeRequired('encrypt'),
              child: const Text('Encrypt'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _fheNativeRequired('decrypt'),
              child: const Text('Decrypt'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outputCard() {
    return _Card(
      title: 'Output',
      subtitle: _activeTask,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 260, maxHeight: 560),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xee050806),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x223dffb5)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              _output,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xffb8f28b),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OctraRpcClient {
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);
  int _id = 1;

  Future<Object?> call({
    required String url,
    required String method,
    required List<Object?> params,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final request = await _client.postUrl(Uri.parse(url.trim()));
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': _id++,
        'method': method,
        'params': params,
      }),
    );
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RpcException('HTTP ${response.statusCode}: $body');
    }
    if (decoded['error'] != null) {
      throw RpcException(jsonEncode(decoded['error']));
    }
    return decoded['result'];
  }

  void close() => _client.close(force: true);
}

class RpcException implements Exception {
  const RpcException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xffaebfac))),
            const SizedBox(height: 16),
            ...children
                .expand((child) => [child, const SizedBox(height: 12)])
                .toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xcc101b16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x263dffb5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.75, -0.85),
          radius: 1.35,
          colors: [Color(0x553dffb5), Color(0xff07100d), Color(0xff020403)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  int lines = 1,
  bool mono = false,
}) {
  return TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines,
    keyboardType: lines == 1 ? TextInputType.text : TextInputType.multiline,
    style: mono ? const TextStyle(fontFamily: 'monospace', fontSize: 13) : null,
    decoration: InputDecoration(labelText: label),
  );
}

List<dynamic> _parseJsonArray(String raw) {
  final decoded = jsonDecode(raw.trim().isEmpty ? '[]' : raw);
  if (decoded is! List) throw const FormatException('expected JSON array');
  return decoded;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {'value': value};
}

String? _extractFee(Object? result) {
  final map = _map(result);
  for (final key in [
    'recommended',
    'recommended_fee',
    'fast',
    'base_fee',
    'minimum',
  ]) {
    final value = map[key];
    if (value != null) return value.toString();
  }
  return null;
}

String _octToRaw(String text) {
  final value = double.tryParse(text.isEmpty ? '0' : text);
  if (value == null || value < 0) {
    throw const FormatException('invalid OCT amount');
  }
  return (value * _octScale).round().toString();
}

String _pretty(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
