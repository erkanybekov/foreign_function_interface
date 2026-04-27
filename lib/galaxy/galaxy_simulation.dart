import 'dart:ffi' as ffi;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:ffi/ffi.dart';

enum GalaxyComputeBackend { dart, cFfi }

const double _galaxySoftening = 0.025;
const double _galaxyCenterEpsilon = 0.0016;
const double _goldenRatioFraction = 0.61803398875;
const double _secondaryFraction = 0.75487766625;

double _fractional(double value) => value - value.floorToDouble();

void respawnGalaxyParticle(
  Float32List particles,
  int particleIndex, {
  GalaxyStepConfig config = const GalaxyStepConfig(),
}) {
  final offset = particleIndex * galaxyParticleStride;
  final angleSeed = _fractional((particleIndex + 1) * _goldenRatioFraction);
  final radiusSeed = _fractional((particleIndex + 1) * _secondaryFraction);
  final angle = angleSeed * math.pi * 2.0;
  final radius = config.respawnRadius * (0.32 + radiusSeed * 0.68);
  final sinAngle = math.sin(angle);
  final cosAngle = math.cos(angle);
  final tangentialSpeed = config.swirl * (0.22 + radius * 0.4);

  particles[offset] = (cosAngle * radius).toDouble();
  particles[offset + 1] = (sinAngle * radius).toDouble();
  particles[offset + 2] = (-sinAngle * tangentialSpeed).toDouble();
  particles[offset + 3] = (cosAngle * tangentialSpeed).toDouble();
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
  final escapeRadiusSquared = config.escapeRadius * config.escapeRadius;

  for (var index = 0; index < particleCount; index++) {
    final offset = index * galaxyParticleStride;
    var x = particles[offset].toDouble();
    var y = particles[offset + 1].toDouble();
    var vx = particles[offset + 2].toDouble();
    var vy = particles[offset + 3].toDouble();
    final radiusSquared = x * x + y * y;

    if (radiusSquared > escapeRadiusSquared ||
        radiusSquared < _galaxyCenterEpsilon) {
      respawnGalaxyParticle(particles, index, config: config);
      continue;
    }

    final inverseRadius = 1.0 / math.sqrt(radiusSquared + _galaxySoftening);
    final radialAcceleration = config.centerPull * inverseRadius;
    final tangentialAcceleration = config.swirl * (0.35 + inverseRadius * 0.45);
    final ax = (-x * radialAcceleration) - (y * tangentialAcceleration);
    final ay = (-y * radialAcceleration) + (x * tangentialAcceleration);

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
    final stopwatch = Stopwatch()..start();
    stepGalaxyParticlesDart(
      _particles,
      _particleCount,
      dtSeconds,
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
    final stopwatch = Stopwatch()..start();
    _core.updateGalaxyParticles(
      particles: pointer,
      particleCount: _particleCount,
      dtSeconds: dtSeconds,
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
