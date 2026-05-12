part of '../galaxy_benchmark_page.dart';


// Benchmark takeaway copy and lesson panel.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

class _BenchmarkVerdict {
  const _BenchmarkVerdict.warming()
    : isReady = false,
      winner = null,
      gainPercent = 0;

  const _BenchmarkVerdict.ready({
    required GalaxyComputeBackend this.winner,
    required this.gainPercent,
  }) : isReady = true;

  final bool isReady;
  final GalaxyComputeBackend? winner;
  final double gainPercent;

  String get summary {
    if (!isReady) {
      return 'Warming';
    }
    return '${_backendShortLabel(winner!)} wins';
  }

  String get title {
    if (!isReady) {
      return 'Benchmark is warming up';
    }
    if (winner == GalaxyComputeBackend.dart) {
      return 'Dart wins in this workload';
    }
    return '${_backendShortLabel(winner!)} wins in this workload';
  }

  String get body {
    if (!isReady) {
      return 'Wait for a few frames before reading the numbers.';
    }
    if (winner == GalaxyComputeBackend.dart) {
      return 'This is expected: the math is simple, Dart AOT is fast, and FFI still has boundary cost. FFI is not an automatic speed button.';
    }
    return 'Here the native batch is large enough to pay for the FFI boundary and still come out ahead. Compare C and Rust by keeping the particle count and substeps fixed.';
  }

  String get gainLabel {
    if (!isReady) {
      return 'collecting samples';
    }
    return '${gainPercent.toStringAsFixed(1)}% over next';
  }
}

class _BenchmarkLessonPanel extends StatelessWidget {
  const _BenchmarkLessonPanel({required this.verdict});

  final _BenchmarkVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Benchmark lesson',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(
                label: Text(verdict.gainLabel),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(verdict.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(verdict.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LessonChip(
                icon: Icons.check_circle,
                text: 'Good for native SDKs',
              ),
              _LessonChip(icon: Icons.call_merge, text: 'Batch native work'),
              _LessonChip(icon: Icons.warning_amber, text: 'Avoid tiny calls'),
              _LessonChip(
                icon: Icons.rocket_launch,
                text: 'Measure release builds',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({required this.icon, required this.text});

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
