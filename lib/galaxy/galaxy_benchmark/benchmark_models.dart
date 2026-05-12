part of '../galaxy_benchmark_page.dart';

/// Presets and shared types for the galaxy benchmark (separate from widgets).
const List<int> galaxyComputeParticlePresets = <int>[8192, 32768, 65536];
const List<int> galaxySubstepPresets = <int>[1, 4, 8];
const int galaxyVisibleParticleLimit = 3072;

enum GalaxyBenchmarkViewMode { compare, single }

enum GalaxyVisualEffect {
  nebula,
  starWarp,
  gravitationalLens,
  aurora,
  riskHeatmap,
  deviceFingerprint,
}

typedef GalaxyBenchmarkBackendBuilder =
    GalaxySimulationBackend Function(
      GalaxyComputeBackend kind,
      int particleCount,
      GalaxyStepConfig config,
      BankCoreFfi? core,
    );
