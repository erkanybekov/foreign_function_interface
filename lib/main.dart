import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'galaxy/galaxy_benchmark_page.dart';
import 'platform_adaptive.dart';

void main() {
  runApp(const MyApp());
}

abstract class BankLabService {
  int add(int a, int b);
  bool isValidPan(String pan);
  bool isValidIban(String iban);
  RiskScore scoreTransaction(TransactionRiskInput input);
  String nativeErrorMessage(int code);
}

class FfiBankLabService implements BankLabService {
  FfiBankLabService({BankCoreFfi? core}) : _core = core ?? BankCoreFfi();

  final BankCoreFfi _core;

  @override
  int add(int a, int b) => _core.add(a, b);

  @override
  bool isValidPan(String pan) => _core.isValidPan(pan);

  @override
  bool isValidIban(String iban) => _core.isValidIban(iban);

  @override
  RiskScore scoreTransaction(TransactionRiskInput input) {
    return _core.scoreTransaction(input);
  }

  @override
  String nativeErrorMessage(int code) => _core.nativeErrorMessage(code);
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.service,
    this.core,
    this.benchmarkBackendBuilder,
  });

  final BankLabService? service;
  final BankCoreFfi? core;
  final GalaxyBenchmarkBackendBuilder? benchmarkBackendBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFI Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: _HomeShell(
        service: service,
        core: core,
        benchmarkBackendBuilder: benchmarkBackendBuilder,
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.service,
    required this.core,
    required this.benchmarkBackendBuilder,
  });

  final BankLabService? service;
  final BankCoreFfi? core;
  final GalaxyBenchmarkBackendBuilder? benchmarkBackendBuilder;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  static const List<_HomeDestination> _destinations = <_HomeDestination>[
    _HomeDestination(icon: Icons.route, label: 'Examples'),
    _HomeDestination(icon: Icons.terminal, label: 'Setup'),
    _HomeDestination(icon: Icons.account_balance, label: 'Live Calls'),
    _HomeDestination(icon: Icons.shield, label: 'Usage Map'),
    _HomeDestination(icon: Icons.blur_on, label: 'Performance'),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentPage = switch (_selectedIndex) {
      0 => FfiGuidePage(
        onOpenSetup: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
        onOpenBankLab: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        onOpenAntiFraud: () {
          setState(() {
            _selectedIndex = 3;
          });
        },
        onOpenBenchmark: () {
          setState(() {
            _selectedIndex = 4;
          });
        },
      ),
      1 => const SetupGuidePage(),
      2 => BankFfiLabPage(service: widget.service),
      3 => const AntiFraudFfiFitPage(),
      _ => GalaxyBenchmarkPage(
        core: widget.core,
        backendBuilder: widget.benchmarkBackendBuilder,
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = usesNavigationRail(
          context,
          constraints.maxWidth,
        );

        return Scaffold(
          body:
              useNavigationRail
                  ? Row(
                    children: <Widget>[
                      SafeArea(
                        right: false,
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          labelType: NavigationRailLabelType.all,
                          destinations:
                              _destinations
                                  .map(
                                    (destination) => NavigationRailDestination(
                                      icon: Icon(destination.icon),
                                      label: Text(destination.label),
                                    ),
                                  )
                                  .toList(),
                          onDestinationSelected: _selectDestination,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: currentPage),
                    ],
                  )
                  : currentPage,
          bottomNavigationBar:
              useNavigationRail
                  ? null
                  : _AdaptiveBottomNavigationBar(
                    selectedIndex: _selectedIndex,
                    destinations: _destinations,
                    onDestinationSelected: _selectDestination,
                  ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _HomeDestination {
  const _HomeDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _AdaptiveBottomNavigationBar extends StatelessWidget {
  const _AdaptiveBottomNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<_HomeDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isApplePlatform(context)) {
      return CupertinoTabBar(
        currentIndex: selectedIndex,
        activeColor: colorScheme.primary,
        inactiveColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        items:
            destinations
                .map(
                  (destination) => BottomNavigationBarItem(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
                )
                .toList(),
        onTap: onDestinationSelected,
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations:
          destinations
              .map(
                (destination) => NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                ),
              )
              .toList(),
      onDestinationSelected: onDestinationSelected,
    );
  }
}

class FfiGuidePage extends StatelessWidget {
  const FfiGuidePage({
    super.key,
    required this.onOpenSetup,
    required this.onOpenBankLab,
    required this.onOpenAntiFraud,
    required this.onOpenBenchmark,
  });

  final VoidCallback onOpenSetup;
  final VoidCallback onOpenBankLab;
  final VoidCallback onOpenAntiFraud;
  final VoidCallback onOpenBenchmark;

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      title: 'FFI Examples',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _GuideHeroPanel(
            onOpenSetup: onOpenSetup,
            onOpenBankLab: onOpenBankLab,
            onOpenAntiFraud: onOpenAntiFraud,
            onOpenBenchmark: onOpenBenchmark,
          ),
          const SizedBox(height: 12),
          const _FfiMentalModelPanel(),
          const SizedBox(height: 12),
          const _ExampleUsagePanel(),
          const SizedBox(height: 12),
          const _GuideFlowPanel(),
          const SizedBox(height: 12),
          const _ImplementationBasicsPanel(),
          const SizedBox(height: 12),
          const _GuideApplicationsPanel(),
          const SizedBox(height: 12),
          const _GuideDecisionPanel(),
          const SizedBox(height: 12),
          const _FfiBestPracticesPanel(),
        ],
      ),
    );
  }
}

class _GuideHeroPanel extends StatelessWidget {
  const _GuideHeroPanel({
    required this.onOpenSetup,
    required this.onOpenBankLab,
    required this.onOpenAntiFraud,
    required this.onOpenBenchmark,
  });

  final VoidCallback onOpenSetup;
  final VoidCallback onOpenBankLab;
  final VoidCallback onOpenAntiFraud;
  final VoidCallback onOpenBenchmark;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FFI examples and usages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Each example shows what crosses the Dart/native boundary and where it fits in a banking app.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _GuidePill(icon: Icons.link, text: 'Bridge to native code'),
              _GuidePill(icon: Icons.inventory_2, text: 'Wrap vendor SDKs'),
              _GuidePill(icon: Icons.call_merge, text: 'Batch heavy work'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onOpenSetup,
                icon: const Icon(Icons.terminal),
                label: const Text('Open Setup Guide'),
              ),
              FilledButton.icon(
                onPressed: onOpenBankLab,
                icon: const Icon(Icons.account_balance),
                label: const Text('Open Live Calls'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenAntiFraud,
                icon: const Icon(Icons.shield),
                label: const Text('Open Usage Map'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBenchmark,
                icon: const Icon(Icons.speed),
                label: const Text('Open Performance Example'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FfiMentalModelPanel extends StatelessWidget {
  const _FfiMentalModelPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Mental image', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Flutter keeps the UI. Dart prepares native-safe data. FFI crosses into a compiled library. Dart maps the result back to app objects.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final nodeWidth =
                  compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 72) / 4;
              final nodes = const <Widget>[
                _BoundaryNode(
                  icon: Icons.phone_android,
                  title: 'Flutter UI',
                  body: 'Buttons, forms, state',
                ),
                _BoundaryNode(
                  icon: Icons.code,
                  title: 'Dart facade',
                  body: 'Clean app API',
                ),
                _BoundaryNode(
                  icon: Icons.memory,
                  title: 'FFI boundary',
                  body: 'Pointers, structs, char*',
                ),
                _BoundaryNode(
                  icon: Icons.precision_manufacturing,
                  title: 'Native library',
                  body: 'C / Rust / vendor SDK',
                ),
              ];

              if (compact) {
                return Column(
                  children:
                      nodes
                          .map(
                            (node) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(width: nodeWidth, child: node),
                            ),
                          )
                          .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var index = 0; index < nodes.length; index++) ...[
                    SizedBox(width: nodeWidth, child: nodes[index]),
                    if (index != nodes.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 34),
                        child: Icon(Icons.arrow_forward),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BoundaryNode extends StatelessWidget {
  const _BoundaryNode({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _ExampleUsagePanel extends StatelessWidget {
  const _ExampleUsagePanel();

  static const List<
    ({
      IconData icon,
      String example,
      String boundary,
      String usage,
      String fit,
      String dartCode,
      String nativeCode,
    })
  >
  examples = [
    (
      icon: Icons.functions,
      example: 'Scalar warm-up',
      boundary: 'Dart int -> C int32_t',
      usage: 'Prove that symbols, library loading, and bindings work.',
      fit: 'Good for learning, not a real banking feature.',
      dartCode: 'final result = bankCore.add(1200, 37);',
      nativeCode: 'int32_t bank_add(int32_t a, int32_t b);',
    ),
    (
      icon: Icons.credit_card,
      example: 'PAN / IBAN validation',
      boundary: 'Dart String -> native char*',
      usage: 'Reuse the same validator library across mobile/backend/tools.',
      fit: 'Worth it only if that native validator already exists.',
      dartCode: 'final ok = bankCore.isValidPan(pan);',
      nativeCode: 'int32_t bank_validate_pan(const char* pan);',
    ),
    (
      icon: Icons.rule,
      example: 'Transaction risk score',
      boundary: 'Dart struct* -> C fills output struct*',
      usage: 'Show local scoring hints before sending data to backend.',
      fit: 'Final approve/block still belongs on the server.',
      dartCode: 'final score = bankCore.scoreTransaction(input);',
      nativeCode: 'int32_t bank_score_transaction(input*, output*);',
    ),
    (
      icon: Icons.fingerprint,
      example: 'Device risk SDK',
      boundary: 'Flutter facade -> native vendor SDK',
      usage: 'Collect emulator/root/hook/session integrity signals.',
      fit: 'Strong AntiFraud use case when vendor SDK is native-only.',
      dartCode: 'final signals = deviceRisk.collectSignals();',
      nativeCode: 'int32_t vendor_collect_signals(Signals* out);',
    ),
    (
      icon: Icons.document_scanner,
      example: 'OCR / document scan',
      boundary: 'Image buffer/handle -> native scan engine',
      usage: 'ID scan, card scan, liveness, or document onboarding.',
      fit: 'Use audited SDKs; do not build banking OCR from scratch.',
      dartCode: 'final result = scanner.scan(imageHandle);',
      nativeCode: 'int32_t scan_document(ImageHandle*, ScanResult*);',
    ),
    (
      icon: Icons.speed,
      example: 'Batched compute',
      boundary: 'Native buffer pointer -> many items processed in one call',
      usage: 'Performance demo: one FFI call updates many particles.',
      fit: 'Only makes sense when work is batched enough.',
      dartCode: 'core.updateGalaxyParticlesBatched(...);',
      nativeCode: 'int32_t update_particles(float* particles, int32_t count);',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Examples and usages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Use this as the team-facing map: example, boundary, product usage, and whether FFI is actually justified.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    examples
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: _ExampleUsageCard(
                              icon: item.icon,
                              example: item.example,
                              boundary: item.boundary,
                              usage: item.usage,
                              fit: item.fit,
                              dartCode: item.dartCode,
                              nativeCode: item.nativeCode,
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuideFlowPanel extends StatelessWidget {
  const _GuideFlowPanel();

  static const List<({IconData icon, String title, String body})> steps = [
    (
      icon: Icons.input,
      title: '1. Dart prepares data',
      body: 'Values become int32, char*, struct*, or a native buffer.',
    ),
    (
      icon: Icons.memory,
      title: '2. FFI crosses the boundary',
      body: 'Dart calls an exported C ABI symbol from a native library.',
    ),
    (
      icon: Icons.precision_manufacturing,
      title: '3. Native code works',
      body: 'C, Rust, or a vendor SDK validates, scores, scans, or computes.',
    ),
    (
      icon: Icons.output,
      title: '4. Dart maps the result',
      body: 'Return codes become booleans, exceptions, or domain objects.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'Step by step', children: steps);
  }
}

class _GuideApplicationsPanel extends StatelessWidget {
  const _GuideApplicationsPanel();

  static const List<({IconData icon, String title, String body})> steps = [
    (
      icon: Icons.security,
      title: 'Fraud / device SDK',
      body: 'Use FFI when the bank already has a native risk SDK.',
    ),
    (
      icon: Icons.document_scanner,
      title: 'OCR / document scan',
      body: 'Wrap native scanning engines for ID, card, or document flows.',
    ),
    (
      icon: Icons.enhanced_encryption,
      title: 'Audited crypto wrapper',
      body:
          'Call verified native crypto or HSM client libraries. Do not invent crypto.',
    ),
    (
      icon: Icons.speed,
      title: 'Risk engine',
      body: 'Batch transaction scoring when a native engine already exists.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'Banking applications', children: steps);
  }
}

class _ImplementationBasicsPanel extends StatelessWidget {
  const _ImplementationBasicsPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Implementation basics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Minimum path: export C symbol, bind it in Dart, hide raw FFI behind a small facade.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _BasicStepCard(
                        title: '1. Native C ABI',
                        body:
                            'Export stable C functions. Avoid C++ ABI at the boundary.',
                        code:
                            'FFI_PLUGIN_EXPORT int32_t bank_add(int32_t a, int32_t b);',
                      ),
                      _BasicStepCard(
                        title: '2. Dart binding',
                        body:
                            'Use generated bindings or lookupFunction for small demos.',
                        code:
                            "library.lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>('bank_add');",
                      ),
                      _BasicStepCard(
                        title: '3. Public facade',
                        body:
                            'Expose domain methods. Keep Pointer, malloc, calloc out of UI.',
                        code:
                            'class BankCoreFfi { int add(int a, int b) => _bindings.bank_add(a, b); }',
                      ),
                      _BasicStepCard(
                        title: '4. Memory contract',
                        body:
                            'Allocate native inputs in Dart, free them in finally.',
                        code:
                            'final p = text.toNativeUtf8(allocator: calloc); try { ... } finally { calloc.free(p); }',
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuideDecisionPanel extends StatelessWidget {
  const _GuideDecisionPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Decision rule', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 680;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: const _DecisionColumn(
                      icon: Icons.check_circle,
                      title: 'Use FFI when',
                      items: <String>[
                        'There is an existing C, C++, Rust, or vendor library.',
                        'The native call can process data in batches.',
                        'You need platform SDKs that Dart cannot call directly.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _DecisionColumn(
                      icon: Icons.cancel,
                      title: 'Avoid FFI when',
                      items: <String>[
                        'The logic is simple and already fast in Dart.',
                        'You would call native code once per tiny item.',
                        'You need Flutter web support for the same path.',
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FfiBestPracticesPanel extends StatelessWidget {
  const _FfiBestPracticesPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Best practices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 680;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: const _DecisionColumn(
                      icon: Icons.verified,
                      title: 'Do',
                      items: <String>[
                        'Prefer generated bindings for real APIs.',
                        'Batch work. One native call should process many items.',
                        'Document ownership: who allocates, who frees.',
                        'Map native error codes to Dart domain errors.',
                        'Benchmark release builds, not debug builds.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _DecisionColumn(
                      icon: Icons.report_gmailerrorred,
                      title: 'Do not',
                      items: <String>[
                        'Do not store Dart-owned pointers in native code.',
                        'Do not call FFI once per tiny object in a loop.',
                        'Do not block the UI isolate with long native work.',
                        'Do not put secrets, PAN, IBAN, or tokens in logs.',
                        'Do not write custom banking crypto in demo native code.',
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SetupGuidePage extends StatelessWidget {
  const SetupGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      title: 'Setup Guide',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _SetupHeroPanel(),
          SizedBox(height: 12),
          _SetupProjectMapPanel(),
          SizedBox(height: 12),
          _SetupFromZeroPanel(),
          SizedBox(height: 12),
          _SetupRustPanel(),
          SizedBox(height: 12),
          _SetupRunPanel(),
          SizedBox(height: 12),
          _SetupAppleBuildPanel(),
          SizedBox(height: 12),
          _SetupVerifyPanel(),
          SizedBox(height: 12),
          _SetupTroubleshootingPanel(),
        ],
      ),
    );
  }
}

class _SetupHeroPanel extends StatelessWidget {
  const _SetupHeroPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.terminal,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'How to setup this FFI demo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This is the installation guide for the repo: Flutter app, local FFI plugin, C ABI, and the Rust galaxy backend used by the performance screen.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _GuidePill(icon: Icons.flutter_dash, text: 'Flutter app'),
              _GuidePill(icon: Icons.memory, text: 'C FFI plugin'),
              _GuidePill(icon: Icons.construction, text: 'Rust backend'),
              _GuidePill(icon: Icons.fact_check, text: 'Verify commands'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupProjectMapPanel extends StatelessWidget {
  const _SetupProjectMapPanel();

  static const List<({IconData icon, String title, String body})> items = [
    (
      icon: Icons.extension,
      title: 'Local FFI plugin',
      body: 'packages/bank_core_ffi is a Flutter ffiPlugin dependency.',
    ),
    (
      icon: Icons.hub,
      title: 'C ABI',
      body: 'src/bank_core_ffi.h and .c export stable C symbols for Dart.',
    ),
    (
      icon: Icons.code,
      title: 'Dart facade',
      body: 'lib/bank_core_ffi.dart hides Pointer, calloc, and lookup details.',
    ),
    (
      icon: Icons.construction,
      title: 'Rust crate',
      body: 'rust/src/lib.rs exports extra galaxy benchmark symbols.',
    ),
    (
      icon: Icons.apple,
      title: 'Apple build script',
      body: 'scripts/build_rust_apple.sh builds Rust static libraries.',
    ),
    (
      icon: Icons.settings,
      title: 'Podspec hook',
      body:
          'iOS and macOS podspecs run the Rust build during CocoaPods builds.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'What was set up', children: items);
  }
}

class _SetupFromZeroPanel extends StatelessWidget {
  const _SetupFromZeroPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Starting from zero',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'These are the commands a developer would use to create the same shape: an app plus a local FFI plugin package.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Create app and FFI plugin',
                        body:
                            'Use this only when bootstrapping a new project. This repo already contains the generated app and plugin.',
                        code: '''
flutter create foreign_function_interface
cd foreign_function_interface
flutter create --template=plugin_ffi packages/bank_core_ffi''',
                        maxLines: 5,
                      ),
                      _SetupCommandCard(
                        title: 'Wire the local plugin',
                        body:
                            'Add the path dependency to the app pubspec, then fetch dependencies.',
                        code: '''
dependencies:
  bank_core_ffi:
    path: packages/bank_core_ffi
  ffi: ^2.2.0''',
                        maxLines: 6,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupRustPanel extends StatelessWidget {
  const _SetupRustPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Install Rust for the Rust FFI backend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Apple builds need Cargo because the Rust static library is built during the macOS/iOS CocoaPods phase.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Install rustup and Cargo',
                        body:
                            'Install Rust, load Cargo into the current shell, then confirm the toolchain is visible.',
                        code: r'''
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo --version
rustup --version''',
                        maxLines: 6,
                      ),
                      _SetupCommandCard(
                        title: 'Add Apple targets',
                        body:
                            'macOS needs Darwin targets. iOS simulator builds also need iOS and simulator targets.',
                        code: '''
rustup target add aarch64-apple-darwin x86_64-apple-darwin
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios''',
                        maxLines: 4,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupRunPanel extends StatelessWidget {
  const _SetupRunPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Run this repo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'After Rust is available, Flutter can fetch the local plugin and run the app. The first Apple build also compiles the Rust crate.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Get packages',
                        body:
                            'Run from the repository root so the app resolves packages/bank_core_ffi.',
                        code: 'flutter pub get',
                      ),
                      _SetupCommandCard(
                        title: 'Run the desktop app',
                        body:
                            'macOS is the fastest path for trying all screens locally.',
                        code: 'flutter run -d macos',
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupAppleBuildPanel extends StatelessWidget {
  const _SetupAppleBuildPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'How the Rust build is connected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'The app does not ask developers to run Cargo manually on every build. The iOS and macOS podspecs call the script below, and that script builds libbank_core_ffi_rust.a for the active Apple architecture.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const _CodeBlock(
            code: '''
packages/bank_core_ffi/scripts/build_rust_apple.sh
packages/bank_core_ffi/ios/bank_core_ffi.podspec
packages/bank_core_ffi/macos/bank_core_ffi.podspec
packages/bank_core_ffi/rust/Cargo.toml''',
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          const _GuideTile(
            icon: Icons.tune,
            title: 'Debug Rust is optimized',
            body:
                'rust/Cargo.toml sets profile.dev opt-level = 3 so Debug app runs do not benchmark unoptimized Rust.',
          ),
        ],
      ),
    );
  }
}

class _SetupVerifyPanel extends StatelessWidget {
  const _SetupVerifyPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Verify the setup',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Use these checks before demoing the app or changing native bindings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'App checks',
                        body:
                            'Analyze and run the widget/unit tests from the root.',
                        code: '''
flutter analyze
flutter test''',
                        maxLines: 4,
                      ),
                      _SetupCommandCard(
                        title: 'Plugin checks',
                        body:
                            'The plugin tests compile C and use Cargo when it is installed.',
                        code: '''
cd packages/bank_core_ffi
flutter analyze
flutter test''',
                        maxLines: 5,
                      ),
                      _SetupCommandCard(
                        title: 'Apple packaging check',
                        body:
                            'This exercises CocoaPods, the script phase, C, and Rust linking.',
                        code: 'flutter build macos --debug',
                      ),
                      _SetupCommandCard(
                        title: 'Regenerate bindings after ABI changes',
                        body:
                            'Only needed when src/bank_core_ffi.h changes and generated Dart bindings must be refreshed.',
                        code: '''
cd packages/bank_core_ffi
dart run ffigen --config ffigen.yaml''',
                        maxLines: 4,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupTroubleshootingPanel extends StatelessWidget {
  const _SetupTroubleshootingPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.build_circle,
                  title: 'If Cargo is not found',
                  items: <String>[
                    r'Run source "$HOME/.cargo/env" or reopen the terminal.',
                    'Check cargo --version before running Flutter again.',
                    r'Make sure Xcode build phases can see $HOME/.cargo/bin.',
                    'The build script prepends common Cargo/Homebrew paths.',
                  ],
                ),
              ),
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.devices,
                  title: 'Platform notes',
                  items: <String>[
                    'macOS and iOS link C plus Rust through CocoaPods.',
                    'Android currently exposes the Dart and C FFI paths.',
                    'Linux and Windows files exist, but need local toolchains.',
                    'Flutter web cannot use dart:ffi.',
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupCommandCard extends StatelessWidget {
  const _SetupCommandCard({
    required this.title,
    required this.body,
    required this.code,
    this.maxLines = 3,
  });

  final String title;
  final String body;
  final String code;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 10),
            _CodeBlock(code: code, maxLines: maxLines),
          ],
        ),
      ),
    );
  }
}

class _GuideGridPanel extends StatelessWidget {
  const _GuideGridPanel({required this.title, required this.children});

  final String title;
  final List<({IconData icon, String title, String body})> children;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 680;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    children
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: _GuideTile(
                              icon: item.icon,
                              title: item.title,
                              body: item.body,
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AntiFraudFfiFitPage extends StatelessWidget {
  const AntiFraudFfiFitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      title: 'Usage Map',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const _AntiFraudHeroPanel(),
          const SizedBox(height: 12),
          const _AntiFraudFlowPanel(),
          const SizedBox(height: 12),
          const _AntiFraudFitMatrixPanel(),
          const SizedBox(height: 12),
          const _AntiFraudDecisionPanel(),
        ],
      ),
    );
  }
}

class _AntiFraudHeroPanel extends StatelessWidget {
  const _AntiFraudHeroPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'BI.ZONE AntiFraud usage map',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Use this screen to decide where FFI belongs. BI.ZONE AntiFraud is server-side fraud analytics; Flutter FFI is for client-side native SDK pieces.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _GuidePill(icon: Icons.check_circle, text: 'Good: native SDK'),
              _GuidePill(icon: Icons.call_merge, text: 'Good: batched signals'),
              _GuidePill(icon: Icons.cancel, text: 'Bad: server rules in app'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AntiFraudFlowPanel extends StatelessWidget {
  const _AntiFraudFlowPanel();

  static const List<({IconData icon, String title, String body})> steps = [
    (
      icon: Icons.phone_iphone,
      title: '1. App collects safe signals',
      body: 'Device integrity, session metadata, app version, risk hints.',
    ),
    (
      icon: Icons.memory,
      title: '2. FFI wraps native SDK',
      body: 'Flutter calls C ABI code from a vendor/device/security library.',
    ),
    (
      icon: Icons.cloud_upload,
      title: '3. Backend sends event',
      body: 'Server sends transaction/session data to AntiFraud.',
    ),
    (
      icon: Icons.rule,
      title: '4. AntiFraud decides',
      body: 'Rules, models, threat intel, and analysts produce the action.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'End-to-end flow', children: steps);
  }
}

class _AntiFraudFitMatrixPanel extends StatelessWidget {
  const _AntiFraudFitMatrixPanel();

  static const List<({IconData icon, String title, String body})> items = [
    (
      icon: Icons.fingerprint,
      title: 'Device signals',
      body:
          'Worth it if a native SDK already detects emulator, root, hook, remote control, or device reputation.',
    ),
    (
      icon: Icons.document_scanner,
      title: 'Document / OCR SDK',
      body:
          'Worth it for native ID scan, liveness, card scan, or image pipeline libraries.',
    ),
    (
      icon: Icons.enhanced_encryption,
      title: 'Crypto / secure storage wrapper',
      body:
          'Worth it only for audited libraries or platform SDKs. Do not write custom crypto.',
    ),
    (
      icon: Icons.rule_folder,
      title: 'Fraud rules and models',
      body:
          'Usually not worth it in the app. Keep business rules and model decisions on the server.',
    ),
    (
      icon: Icons.person_search,
      title: 'User behavior analytics',
      body:
          'Collect events in Flutter. Analyze them server-side where the full session context exists.',
    ),
    (
      icon: Icons.speed,
      title: 'Local scoring',
      body:
          'Use only for low-risk hints. Final approve/review/block should stay backend-controlled.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'Fit matrix', children: items);
  }
}

class _AntiFraudDecisionPanel extends StatelessWidget {
  const _AntiFraudDecisionPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.thumb_up,
                  title: 'Profitable / sane',
                  items: <String>[
                    'Vendor gives a native mobile SDK.',
                    'The SDK returns compact risk signals.',
                    'One FFI call collects a batch of signals.',
                    'Backend still owns final fraud decision.',
                  ],
                ),
              ),
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.warning_amber,
                  title: 'Bad idea',
                  items: <String>[
                    'Moving AntiFraud rules into the app.',
                    'Trusting client-side approve/block decisions.',
                    'Sending PAN, passwords, tokens, or secrets to logs.',
                    'Calling native code for tiny logic already fast in Dart.',
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BankFfiLabPage extends StatefulWidget {
  const BankFfiLabPage({super.key, this.service});

  final BankLabService? service;

  @override
  State<BankFfiLabPage> createState() => _BankFfiLabPageState();
}

class _BankFfiLabPageState extends State<BankFfiLabPage> {
  late final BankLabService _service = widget.service ?? FfiBankLabService();
  final TextEditingController _panController = TextEditingController(
    text: '4111 1111 1111 1111',
  );
  final TextEditingController _ibanController = TextEditingController(
    text: 'GB82 WEST 1234 5698 7654 32',
  );

  int _amountCents = 1250000;
  int _accountAgeDays = 24;
  int _failedAttempts24h = 3;
  bool _foreignCountry = true;
  bool _nightTime = true;

  int _nativeAddResult = 0;
  bool _panValid = false;
  bool _ibanValid = false;
  String _nativeErrorExample = '';
  RiskScore _riskScore = const RiskScore(
    score: 0,
    decision: RiskDecision.approve,
    flags: <RiskFlag>{},
  );
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _refreshLab(notify: false);
  }

  @override
  void dispose() {
    _panController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  void _refreshLab({bool notify = true}) {
    void refresh() {
      try {
        _nativeAddResult = _service.add(1200, 37);
        _panValid = _service.isValidPan(_panController.text);
        _ibanValid = _service.isValidIban(_ibanController.text);
        _nativeErrorExample = _service.nativeErrorMessage(-2);
        _riskScore = _service.scoreTransaction(
          TransactionRiskInput(
            amountCents: _amountCents,
            accountAgeDays: _accountAgeDays,
            failedAttempts24h: _failedAttempts24h,
            foreignCountry: _foreignCountry,
            nightTime: _nightTime,
          ),
        );
        _lastError = null;
      } catch (error) {
        _lastError = error.toString();
      }
    }

    if (notify) {
      setState(refresh);
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      title: 'Live FFI Calls',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeaderPanel(
            addResult: _nativeAddResult,
            errorMessage: _nativeErrorExample,
          ),
          const SizedBox(height: 12),
          if (_lastError != null) _ErrorPanel(message: _lastError!),
          _ValidationPanel(
            panController: _panController,
            ibanController: _ibanController,
            panValid: _panValid,
            ibanValid: _ibanValid,
            onChanged: (_) => _refreshLab(),
          ),
          const SizedBox(height: 12),
          _RiskPanel(
            amountCents: _amountCents,
            accountAgeDays: _accountAgeDays,
            failedAttempts24h: _failedAttempts24h,
            foreignCountry: _foreignCountry,
            nightTime: _nightTime,
            riskScore: _riskScore,
            onAmountChanged: (value) {
              _amountCents = value;
              _refreshLab();
            },
            onAccountAgeChanged: (value) {
              _accountAgeDays = value;
              _refreshLab();
            },
            onFailedAttemptsChanged: (value) {
              _failedAttempts24h = value;
              _refreshLab();
            },
            onForeignCountryChanged: (value) {
              _foreignCountry = value;
              _refreshLab();
            },
            onNightTimeChanged: (value) {
              _nightTime = value;
              _refreshLab();
            },
          ),
          const SizedBox(height: 12),
          const _LearningRoadmapPanel(),
          const SizedBox(height: 12),
          const _SecurityPanel(),
        ],
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.addResult, required this.errorMessage});

  final int addResult;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live native banking examples',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Flutter calls a small C library. Each card is a concrete example: scalar, strings, structs, and native error mapping.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final tileWidth =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    <Widget>[
                          _FfiPatternTile(
                            icon: Icons.functions,
                            title: 'Scalar call',
                            call: 'bank_add(1200, 37)',
                            result: '$addResult',
                          ),
                          const _FfiPatternTile(
                            icon: Icons.short_text,
                            title: 'String call',
                            call: 'PAN / IBAN -> char*',
                            result: 'C returns valid / invalid',
                          ),
                          const _FfiPatternTile(
                            icon: Icons.view_in_ar,
                            title: 'Struct call',
                            call: 'TransactionRiskInput*',
                            result: 'C fills RiskScore*',
                          ),
                          _FfiPatternTile(
                            icon: Icons.report_gmailerrorred,
                            title: 'Error mapping',
                            call: 'native code -2',
                            result: errorMessage,
                          ),
                        ]
                        .map((tile) => SizedBox(width: tileWidth, child: tile))
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({
    required this.panController,
    required this.ibanController,
    required this.panValid,
    required this.ibanValid,
    required this.onChanged,
  });

  final TextEditingController panController;
  final TextEditingController ibanController;
  final bool panValid;
  final bool ibanValid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '1. Strings: native validators',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Dart sends UTF-8 strings to C. C checks the value and returns 1 or 0.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: panController,
            decoration: InputDecoration(
              labelText: 'PAN / card number',
              helperText: 'Luhn check in C. Spaces and dashes are accepted.',
              prefixIcon: const Icon(Icons.credit_card),
              suffixIcon: _StatusIcon(valid: panValid),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ibanController,
            decoration: InputDecoration(
              labelText: 'IBAN',
              helperText: 'MOD-97 check in C. Lowercase is normalized.',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              suffixIcon: _StatusIcon(valid: ibanValid),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const Chip(
                avatar: Icon(Icons.memory, size: 18),
                label: Text('Native call: char*'),
                visualDensity: VisualDensity.compact,
              ),
              _StatusChip(label: 'PAN', valid: panValid),
              _StatusChip(label: 'IBAN', valid: ibanValid),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskPanel extends StatelessWidget {
  const _RiskPanel({
    required this.amountCents,
    required this.accountAgeDays,
    required this.failedAttempts24h,
    required this.foreignCountry,
    required this.nightTime,
    required this.riskScore,
    required this.onAmountChanged,
    required this.onAccountAgeChanged,
    required this.onFailedAttemptsChanged,
    required this.onForeignCountryChanged,
    required this.onNightTimeChanged,
  });

  final int amountCents;
  final int accountAgeDays;
  final int failedAttempts24h;
  final bool foreignCountry;
  final bool nightTime;
  final RiskScore riskScore;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<int> onAccountAgeChanged;
  final ValueChanged<int> onFailedAttemptsChanged;
  final ValueChanged<bool> onForeignCountryChanged;
  final ValueChanged<bool> onNightTimeChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '2. Structs: transaction risk',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Chip(
                avatar: Icon(Icons.memory, size: 18),
                label: Text('struct*'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dart fills a native input struct. C returns score, decision, and reason flags.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _NativeResultCard(riskScore: riskScore),
          const SizedBox(height: 12),
          Text('Dart input', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _NumberSlider(
            label: 'Amount',
            valueLabel: _formatMoney(amountCents),
            value: amountCents.toDouble(),
            min: 1000,
            max: 3000000,
            divisions: 120,
            onChanged: (value) => onAmountChanged(value.round()),
          ),
          _NumberSlider(
            label: 'Account age',
            valueLabel: '$accountAgeDays days',
            value: accountAgeDays.toDouble(),
            min: 0,
            max: 365,
            divisions: 73,
            onChanged: (value) => onAccountAgeChanged(value.round()),
          ),
          _NumberSlider(
            label: 'Failed attempts',
            valueLabel: '$failedAttempts24h',
            value: failedAttempts24h.toDouble(),
            min: 0,
            max: 6,
            divisions: 6,
            onChanged: (value) => onFailedAttemptsChanged(value.round()),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foreign country'),
            value: foreignCountry,
            onChanged: onForeignCountryChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Night-time transaction'),
            value: nightTime,
            onChanged: onNightTimeChanged,
          ),
          const SizedBox(height: 8),
          Text(
            'Native reason flags',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                riskScore.flags.isEmpty
                    ? const <Widget>[Chip(label: Text('none'))]
                    : riskScore.flags
                        .map((flag) => Chip(label: Text(_riskFlagLabel(flag))))
                        .toList(),
          ),
        ],
      ),
    );
  }
}

class _LearningRoadmapPanel extends StatelessWidget {
  const _LearningRoadmapPanel();

  static const List<({IconData icon, String title, String body})> topics = [
    (
      icon: Icons.hub,
      title: 'C ABI',
      body: 'Exported symbols, dynamic libraries, and stable C signatures.',
    ),
    (
      icon: Icons.category,
      title: 'Native types',
      body: 'int32, char*, structs, opaque handles, arrays, and buffers.',
    ),
    (
      icon: Icons.storage,
      title: 'Memory',
      body: 'Dart allocates native inputs and frees them after each call.',
    ),
    (
      icon: Icons.speed,
      title: 'Performance',
      body: 'Batch heavy work and move long native calls off the UI isolate.',
    ),
    (
      icon: Icons.inventory_2,
      title: 'Packaging',
      body: 'Android .so, Apple frameworks, Windows .dll, and Linux .so.',
    ),
    (
      icon: Icons.security,
      title: 'Banking fit',
      body: 'Wrap audited SDKs, native risk engines, OCR, and device signals.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('FFI roadmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    topics
                        .map(
                          (topic) => SizedBox(
                            width:
                                narrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 10) / 2,
                            child: _RoadmapTile(
                              icon: topic.icon,
                              title: topic.title,
                              body: topic.body,
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Banking guardrails',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _GuardrailRow(
            icon: Icons.no_encryption_gmailerrorred,
            text: 'Do not write custom crypto in demo C code.',
          ),
          const _GuardrailRow(
            icon: Icons.visibility_off,
            text: 'Do not log PAN, IBAN, keys, tokens, or full risk payloads.',
          ),
          const _GuardrailRow(
            icon: Icons.verified_user,
            text: 'Use FFI to wrap audited native SDKs and verified libraries.',
          ),
        ],
      ),
    );
  }
}

class _GuidePill extends StatelessWidget {
  const _GuidePill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleUsageCard extends StatelessWidget {
  const _ExampleUsageCard({
    required this.icon,
    required this.example,
    required this.boundary,
    required this.usage,
    required this.fit,
    required this.dartCode,
    required this.nativeCode,
  });

  final IconData icon;
  final String example;
  final String boundary;
  final String usage;
  final String fit;
  final String dartCode;
  final String nativeCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 22, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    example,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _UsageLine(label: 'Boundary', value: boundary),
            _UsageLine(label: 'Usage', value: usage),
            _UsageLine(label: 'Fit', value: fit),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                final width =
                    narrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;
                final blocks = <Widget>[
                  _LabeledCodeBlock(label: 'Dart usage', code: dartCode),
                  _LabeledCodeBlock(label: 'Native boundary', code: nativeCode),
                ];

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      blocks
                          .map((block) => SizedBox(width: width, child: block))
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageLine extends StatelessWidget {
  const _UsageLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _LabeledCodeBlock extends StatelessWidget {
  const _LabeledCodeBlock({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        _CodeBlock(code: code, maxLines: 3),
      ],
    );
  }
}

class _BasicStepCard extends StatelessWidget {
  const _BasicStepCard({
    required this.title,
    required this.body,
    required this.code,
  });

  final String title;
  final String body;
  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 10),
            _CodeBlock(code: code),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, this.maxLines = 2});

  final String code;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            code,
            maxLines: maxLines,
            style: const TextStyle(
              color: Color(0xFFE6EEF5),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionColumn extends StatelessWidget {
  const _DecisionColumn({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('- '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _FfiPatternTile extends StatelessWidget {
  const _FfiPatternTile({
    required this.icon,
    required this.title,
    required this.call,
    required this.result,
  });

  final IconData icon;
  final String title;
  final String call;
  final String result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(call, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    result,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.valid});

  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Icon(
      valid ? Icons.check_circle : Icons.cancel,
      color: valid ? const Color(0xFF008A5B) : const Color(0xFFC43C3C),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ${valid ? 'VALID' : 'INVALID'}'),
      backgroundColor:
          valid ? const Color(0xFFE0F4EC) : const Color(0xFFFFE6E6),
      side: BorderSide.none,
    );
  }
}

class _DecisionBadge extends StatelessWidget {
  const _DecisionBadge({required this.decision});

  final RiskDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = switch (decision) {
      RiskDecision.approve => const Color(0xFF008A5B),
      RiskDecision.review => const Color(0xFFB97900),
      RiskDecision.block => const Color(0xFFC43C3C),
    };

    return Chip(
      label: Text(_decisionLabel(decision)),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}

class _NativeResultCard extends StatelessWidget {
  const _NativeResultCard({required this.riskScore});

  final RiskScore riskScore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.output, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Native output',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _DecisionBadge(decision: riskScore.decision),
              ],
            ),
            const SizedBox(height: 12),
            _ScoreBar(score: riskScore.score),
            const SizedBox(height: 8),
            Text('Risk score: ${riskScore.score}/100'),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: 10,
        backgroundColor: const Color(0xFFE6E8EB),
        color:
            score >= 70
                ? const Color(0xFFC43C3C)
                : score >= 35
                ? const Color(0xFFB97900)
                : const Color(0xFF008A5B),
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[Expanded(child: Text(label)), Text(valueLabel)]),
        Slider.adaptive(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardrailRow extends StatelessWidget {
  const _GuardrailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6E6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      ),
    );
  }
}

String _formatMoney(int amountCents) {
  final dollars = amountCents ~/ 100;
  final cents = amountCents % 100;
  return '\$$dollars.${cents.toString().padLeft(2, '0')}';
}

String _decisionLabel(RiskDecision decision) {
  return switch (decision) {
    RiskDecision.approve => 'APPROVE',
    RiskDecision.review => 'REVIEW',
    RiskDecision.block => 'BLOCK',
  };
}

String _riskFlagLabel(RiskFlag flag) {
  return switch (flag) {
    RiskFlag.highAmount => 'high amount',
    RiskFlag.newAccount => 'new account',
    RiskFlag.failedAttempts => 'failed attempts',
    RiskFlag.foreignCountry => 'foreign country',
    RiskFlag.nightTime => 'night-time',
  };
}
