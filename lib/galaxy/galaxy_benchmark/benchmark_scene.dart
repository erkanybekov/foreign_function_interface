part of '../galaxy_benchmark_page.dart';


// Per-backend simulation instance and smoothed timing metrics.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

class _BenchmarkSceneState {
  _BenchmarkSceneState({required this.kind, required this.backend});

  final GalaxyComputeBackend kind;
  final GalaxySimulationBackend backend;
  double smoothedStepMicros = 0;
  double smoothedBatchMicros = 0;

  Float32List get particles => backend.particles;

  Duration stepBatch(
    double dtSeconds, {
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final duration = backend.stepBatch(
      dtSeconds,
      substeps: substeps,
      config: config,
    );
    final batchMicros = duration.inMicroseconds.toDouble();
    final stepMicros = batchMicros / substeps;
    smoothedBatchMicros = _smooth(smoothedBatchMicros, batchMicros);
    smoothedStepMicros = _smooth(smoothedStepMicros, stepMicros);
    return duration;
  }

  void reseed(
    int particleCount, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    backend.reseed(particleCount, config: config);
    resetMetrics();
  }

  void resetMetrics() {
    smoothedStepMicros = 0;
    smoothedBatchMicros = 0;
  }

  void dispose() {
    backend.dispose();
  }

  static double _smooth(double previous, double next) {
    if (previous == 0) {
      return next;
    }
    return (previous * 0.88) + (next * 0.12);
  }
}
