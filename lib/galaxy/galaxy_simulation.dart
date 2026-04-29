import 'dart:ffi' as ffi;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:ffi/ffi.dart';

enum GalaxyComputeBackend { dart, cFfi }

const double _goldenRatioFraction = 0.61803398875;
const double _secondaryFraction = 0.75487766625;
const double _tertiaryFraction = 0.41421356237;
const double _quaternaryFraction = 0.56984029099;

double _fractional(double value) => value - value.floorToDouble();

void respawnGalaxyParticle(
  Float32List particles,
  int particleIndex, {
  GalaxyStepConfig config = const GalaxyStepConfig(),
}) {
  final offset = particleIndex * galaxyParticleStride;
  final xSeed = _fractional((particleIndex + 1) * _goldenRatioFraction);
  final ySeed = _fractional((particleIndex + 1) * _secondaryFraction);
  final vxSeed = _fractional((particleIndex + 1) * _tertiaryFraction);
  final vySeed = _fractional((particleIndex + 1) * _quaternaryFraction);

  particles[offset] = ((xSeed * 2.0) - 1.0) * config.respawnRadius;
  particles[offset + 1] = ((ySeed * 2.0) - 1.0) * config.respawnRadius;
  particles[offset + 2] =
      0.010 + (vxSeed - 0.5) * 0.030 + config.centerPull * 0.010;
  particles[offset + 3] = (vySeed - 0.5) * 0.022;
}

void seedGalaxyParticles(
  Float32List particles, {
  GalaxyStepConfig config = const GalaxyStepConfig(),
}) {
  final particleCount = particles.length ~/ galaxyParticleStride;
  for (var index = 0; index < particleCount; index++) {
    respawnGalaxyParticle(particles, index, config: config);
  }
}

void stepGalaxyParticlesDart(
  Float32List particles,
  int particleCount,
  double dtSeconds, {
  GalaxyStepConfig config = const GalaxyStepConfig(),
}) {
  if (dtSeconds <= 0) {
    throw ArgumentError.value(dtSeconds, 'dtSeconds', 'must be positive');
  }
  if (particleCount < 0) {
    throw ArgumentError.value(
      particleCount,
      'particleCount',
      'must not be negative',
    );
  }

  final safeDt = math.min(dtSeconds, 0.05);

  for (var index = 0; index < particleCount; index++) {
    final offset = index * galaxyParticleStride;
    var x = particles[offset].toDouble();
    var y = particles[offset + 1].toDouble();
    var vx = particles[offset + 2].toDouble();
    var vy = particles[offset + 3].toDouble();

    if (x.abs() > config.escapeRadius || y.abs() > config.escapeRadius) {
      respawnGalaxyParticle(particles, index, config: config);
      continue;
    }

    final phase = (index + 1) * 0.031;
    final turbulenceX = math.sin((y * 3.7) + phase);
    final turbulenceY = math.cos((x * 2.9) - phase);
    final ax =
        (config.centerPull * 0.018) + (turbulenceX * config.swirl * 0.010);
    final ay = turbulenceY * config.swirl * 0.008;

    vx = (vx * config.damping) + (ax * safeDt);
    vy = (vy * config.damping) + (ay * safeDt);
    x += vx * safeDt;
    y += vy * safeDt;

    particles[offset] = x;
    particles[offset + 1] = y;
    particles[offset + 2] = vx;
    particles[offset + 3] = vy;
  }
}

void stepGalaxyParticlesDartBatched(
  Float32List particles,
  int particleCount,
  double dtSeconds, {
  required int substeps,
  GalaxyStepConfig config = const GalaxyStepConfig(),
}) {
  if (substeps <= 0) {
    throw ArgumentError.value(substeps, 'substeps', 'must be positive');
  }

  for (var step = 0; step < substeps; step++) {
    stepGalaxyParticlesDart(
      particles,
      particleCount,
      dtSeconds,
      config: config,
    );
  }
}

abstract class GalaxySimulationBackend {
  GalaxyComputeBackend get kind;
  int get particleCount;
  Float32List get particles;

  void reseed(
    int particleCount, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  });
  Duration step(
    double dtSeconds, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  });
  Duration stepBatch(
    double dtSeconds, {
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  });
  void dispose();
}

class DartGalaxySimulationBackend implements GalaxySimulationBackend {
  DartGalaxySimulationBackend({
    required int particleCount,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) : _particleCount = particleCount,
       _particles = Float32List(particleCount * galaxyParticleStride) {
    seedGalaxyParticles(_particles, config: config);
  }

  @override
  final GalaxyComputeBackend kind = GalaxyComputeBackend.dart;

  int _particleCount;
  Float32List _particles;

  @override
  int get particleCount => _particleCount;

  @override
  Float32List get particles => _particles;

  @override
  void reseed(
    int particleCount, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    _particleCount = particleCount;
    _particles = Float32List(particleCount * galaxyParticleStride);
    seedGalaxyParticles(_particles, config: config);
  }

  @override
  Duration step(
    double dtSeconds, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    return stepBatch(dtSeconds, substeps: 1, config: config);
  }

  @override
  Duration stepBatch(
    double dtSeconds, {
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final stopwatch = Stopwatch()..start();
    stepGalaxyParticlesDartBatched(
      _particles,
      _particleCount,
      dtSeconds,
      substeps: substeps,
      config: config,
    );
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  @override
  void dispose() {}
}

class FfiGalaxySimulationBackend implements GalaxySimulationBackend {
  FfiGalaxySimulationBackend({
    required BankCoreFfi core,
    required int particleCount,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) : _core = core {
    reseed(particleCount, config: config);
  }

  final BankCoreFfi _core;

  @override
  final GalaxyComputeBackend kind = GalaxyComputeBackend.cFfi;

  ffi.Pointer<ffi.Float>? _particlesPointer;
  late Float32List _particles;
  int _particleCount = 0;

  @override
  int get particleCount => _particleCount;

  ffi.Pointer<ffi.Float> get pointer {
    final value = _particlesPointer;
    if (value == null) {
      throw StateError('Native particle buffer has been disposed.');
    }
    return value;
  }

  @override
  Float32List get particles => _particles;

  @override
  void reseed(
    int particleCount, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    dispose();
    _particleCount = particleCount;
    _particlesPointer = calloc<ffi.Float>(particleCount * galaxyParticleStride);
    _particles = pointer.asTypedList(particleCount * galaxyParticleStride);
    seedGalaxyParticles(_particles, config: config);
  }

  @override
  Duration step(
    double dtSeconds, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    return stepBatch(dtSeconds, substeps: 1, config: config);
  }

  @override
  Duration stepBatch(
    double dtSeconds, {
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final stopwatch = Stopwatch()..start();
    _core.updateGalaxyParticlesBatched(
      particles: pointer,
      particleCount: _particleCount,
      dtSeconds: dtSeconds,
      substeps: substeps,
      config: config,
    );
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  @override
  void dispose() {
    final value = _particlesPointer;
    if (value != null) {
      calloc.free(value);
      _particlesPointer = null;
    }
  }
}
