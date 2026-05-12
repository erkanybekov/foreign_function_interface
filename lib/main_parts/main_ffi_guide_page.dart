part of '../main.dart';

// Landing page widget that composes the FFI guide sections.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// First tab: narrative FFI guide with shortcuts into Setup, Live Calls, Usage Map, and Benchmark.
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
