part of '../main.dart';

// Educational panels for the FFI Examples tab.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

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
