part of '../main.dart';

// Usage Map tab: where FFI fits for fraud and device analytics.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// Fourth tab: when client-side FFI is appropriate vs server-side fraud products (conceptual only).
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
