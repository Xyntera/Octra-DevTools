import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const OctraDevToolsApp());
}

const _defaultRpcUrl = 'https://octra.network/rpc';

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
          surface: Color(0xff111c17),
          error: Color(0xffff7777),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Georgia',
          bodyColor: const Color(0xffedf8e8),
          displayColor: const Color(0xffedf8e8),
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
  final _sourceController = TextEditingController(text: _starterAml);
  final _rpcController = TextEditingController(text: _defaultRpcUrl);
  final _rpcClient = OctraRpcClient();

  String _activeOutput = 'ABI';
  String _compilerOutput =
      'Compile the project to inspect ABI, assembly, console, and storage output.';
  bool _isCompiling = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _rpcController.dispose();
    _rpcClient.close();
    super.dispose();
  }

  Future<void> _compileAml() async {
    setState(() {
      _isCompiling = true;
      _compilerOutput =
          'Calling octra_compileAml on ${_rpcController.text.trim()} ...';
    });

    try {
      final result = await _rpcClient.call(
        url: _rpcController.text.trim(),
        method: 'octra_compileAml',
        params: [_sourceController.text],
      );
      if (!mounted) return;
      setState(() {
        _activeOutput = 'Compiler';
        _compilerOutput = const JsonEncoder.withIndent('  ').convert(result);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activeOutput = 'Error';
        _compilerOutput = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isCompiling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Atmosphere(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final content = _Workspace(
                  rpcController: _rpcController,
                  sourceController: _sourceController,
                  activeOutput: _activeOutput,
                  compilerOutput: _compilerOutput,
                  isCompiling: _isCompiling,
                  onCompile: _compileAml,
                  onSelectOutput: (tab) => setState(() => _activeOutput = tab),
                );

                if (!wide) {
                  return Column(
                    children: [
                      const _MobileHeader(),
                      Expanded(child: content),
                    ],
                  );
                }

                return Row(
                  children: [
                    const _Sidebar(),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.rpcController,
    required this.sourceController,
    required this.activeOutput,
    required this.compilerOutput,
    required this.isCompiling,
    required this.onCompile,
    required this.onSelectOutput,
  });

  final TextEditingController rpcController;
  final TextEditingController sourceController;
  final String activeOutput;
  final String compilerOutput;
  final bool isCompiling;
  final VoidCallback onCompile;
  final ValueChanged<String> onSelectOutput;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
          sliver: SliverToBoxAdapter(
            child: _HeroPanel(
              rpcController: rpcController,
              isCompiling: isCompiling,
              onCompile: onCompile,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.crossAxisExtent >= 980;
              if (wide) {
                return SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _EditorPanel(controller: sourceController),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 5,
                        child: _OutputPanel(
                          activeOutput: activeOutput,
                          output: compilerOutput,
                          onSelectOutput: onSelectOutput,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SliverList.list(
                children: [
                  _EditorPanel(controller: sourceController),
                  const SizedBox(height: 18),
                  _OutputPanel(
                    activeOutput: activeOutput,
                    output: compilerOutput,
                    onSelectOutput: onSelectOutput,
                  ),
                ],
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
          sliver: SliverGrid.extent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: const [
              _CapabilityCard(
                title: 'Compile',
                status: 'wired',
                body:
                    'AML and multi-file AML through Octra RPC compiler endpoints.',
                icon: Icons.terminal,
              ),
              _CapabilityCard(
                title: 'Deploy & Call',
                status: 'next',
                body:
                    'Sign deploy/call transactions with wallet keys and inspect receipts.',
                icon: Icons.rocket_launch_outlined,
              ),
              _CapabilityCard(
                title: 'FHE Tools',
                status: 'next',
                body:
                    'Client-side encrypt/decrypt helpers for program testing and private params.',
                icon: Icons.lock_outline,
              ),
              _CapabilityCard(
                title: 'Groth16 BN254',
                status: 'research ready',
                body:
                    'Import snarkjs proof, public inputs, and verification key bundles.',
                icon: Icons.hub_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.rpcController,
    required this.isCompiling,
    required this.onCompile,
  });

  final TextEditingController rpcController;
  final bool isCompiling;
  final VoidCallback onCompile;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1fb8f28b),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x55b8f28b)),
                ),
                child: const Text('Native Octra IDE'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isCompiling ? null : onCompile,
                icon: isCompiling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isCompiling ? 'Compiling' : 'Compile AML'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Octra DevTools',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mobile-first AppliedML and Octra Assembly workspace for Android and iOS. '
            'The first version uses the official JSON-RPC compiler and contract tooling; native proof and FHE helpers can be added after the IDE loop is stable.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: rpcController,
            decoration: const InputDecoration(
              labelText: 'RPC endpoint',
              prefixIcon: Icon(Icons.cloud_queue),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'main.aml', subtitle: 'AppliedML editor'),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420, maxHeight: 680),
            child: TextField(
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.45,
                color: Color(0xffe6ffe0),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.activeOutput,
    required this.output,
    required this.onSelectOutput,
  });

  final String activeOutput;
  final String output;
  final ValueChanged<String> onSelectOutput;

  @override
  Widget build(BuildContext context) {
    final tabs = ['ABI', 'Assembly', 'Compiler', 'Storage', 'Error'];

    return _Glass(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'Inspector',
            subtitle: 'ABI, bytecode, disassembly, logs',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                for (final tab in tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: activeOutput == tab,
                      onSelected: (_) => onSelectOutput(tab),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 420, maxHeight: 680),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xe6070b09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x223dffb5)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xffb8f28b),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xd90b1511),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x263dffb5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Octra',
            style: TextStyle(fontSize: 15, color: Color(0xffb8f28b)),
          ),
          SizedBox(height: 4),
          Text(
            'DevTools',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 28),
          _NavItem(icon: Icons.folder_open, label: 'Projects'),
          _NavItem(icon: Icons.code, label: 'Editor'),
          _NavItem(icon: Icons.schema, label: 'ABI Inspector'),
          _NavItem(icon: Icons.receipt_long, label: 'Deploy & Call'),
          _NavItem(icon: Icons.verified_user_outlined, label: 'Verify Source'),
          _NavItem(icon: Icons.scatter_plot, label: 'Proof Lab'),
          Spacer(),
          Text(
            'Research baseline: official Octra IDE docs, contract examples, and Groth16 BN254 toolkit.',
            style: TextStyle(color: Color(0xff9daf9c), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const Icon(Icons.hexagon_outlined, color: Color(0xffb8f28b)),
          const SizedBox(width: 10),
          Text(
            'Octra DevTools',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xffb8f28b)),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.title,
    required this.status,
    required this.body,
    required this.icon,
  });

  final String title;
  final String status;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff66e0ff)),
              const Spacer(),
              Text(status, style: const TextStyle(color: Color(0xffb8f28b))),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Color(0xffbdcdb8), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Color(0xff9daf9c))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.75, -0.85),
          radius: 1.35,
          colors: [Color(0x553dffb5), Color(0xff07100d), Color(0xff020403)],
        ),
      ),
      child: const SizedBox.expand(),
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
  }) async {
    final uri = Uri.parse(url);
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': _id++,
        'method': method,
        'params': params,
      }),
    );

    final response = await request.close().timeout(const Duration(seconds: 30));
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
