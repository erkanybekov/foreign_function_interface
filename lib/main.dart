import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';

import 'galaxy/galaxy_benchmark_page.dart';

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
      title: 'Bank FFI Lab',
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_selectedIndex) {
        0 => FfiGuidePage(
          onOpenBankLab: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
          onOpenAntiFraud: () {
            setState(() {
              _selectedIndex = 2;
            });
          },
          onOpenBenchmark: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
        ),
        1 => BankFfiLabPage(service: widget.service),
        2 => const AntiFraudFfiFitPage(),
        _ => GalaxyBenchmarkPage(
          core: widget.core,
          backendBuilder: widget.benchmarkBackendBuilder,
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.route), label: 'Guide'),
          NavigationDestination(
            icon: Icon(Icons.account_balance),
            label: 'Bank Lab',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield),
            label: 'AntiFraud Fit',
          ),
          NavigationDestination(
            icon: Icon(Icons.blur_on),
            label: 'Galaxy Benchmark',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class FfiGuidePage extends StatelessWidget {
  const FfiGuidePage({
    super.key,
    required this.onOpenBankLab,
    required this.onOpenAntiFraud,
    required this.onOpenBenchmark,
  });

  final VoidCallback onOpenBankLab;
  final VoidCallback onOpenAntiFraud;
  final VoidCallback onOpenBenchmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FFI Guide'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _GuideHeroPanel(
            onOpenBankLab: onOpenBankLab,
            onOpenAntiFraud: onOpenAntiFraud,
            onOpenBenchmark: onOpenBenchmark,
          ),
          const SizedBox(height: 12),
          const _GuideFlowPanel(),
          const SizedBox(height: 12),
          const _GuideApplicationsPanel(),
          const SizedBox(height: 12),
          const _GuideDecisionPanel(),
        ],
      ),
    );
  }
}

class _GuideHeroPanel extends StatelessWidget {
  const _GuideHeroPanel({
    required this.onOpenBankLab,
    required this.onOpenAntiFraud,
    required this.onOpenBenchmark,
  });

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
                  'What FFI is for',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'FFI lets Flutter call native C ABI code. Use it to reuse native libraries or SDKs. Do not expect automatic speedups for simple Dart loops.',
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
                onPressed: onOpenBankLab,
                icon: const Icon(Icons.account_balance),
                label: const Text('Open Bank Lab'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenAntiFraud,
                icon: const Icon(Icons.shield),
                label: const Text('Open AntiFraud Fit'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBenchmark,
                icon: const Icon(Icons.speed),
                label: const Text('Open Benchmark Lesson'),
              ),
            ],
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AntiFraud FFI Fit'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
      ),
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
                  'BI.ZONE AntiFraud: where FFI fits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Think of BI.ZONE AntiFraud as server-side fraud analytics. Flutter FFI is useful only for client-side native SDK pieces: device signals, local scanning, native crypto wrappers, or offline model code.',
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank FFI Lab'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
      ),
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
                  'Native banking core loaded through dart:ffi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Flutter calls a small C library. Each card below shows one common FFI boundary.',
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foreign country'),
            value: foreignCountry,
            onChanged: onForeignCountryChanged,
          ),
          SwitchListTile(
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
        Slider(
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
