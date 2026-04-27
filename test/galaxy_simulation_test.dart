import 'dart:typed_data';

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foreign_function_interface/galaxy/galaxy_simulation.dart';

void main() {
  test('seedGalaxyParticles fills the particle buffer', () {
    final particles = Float32List(3 * galaxyParticleStride);

    seedGalaxyParticles(particles);

    expect(particles.any((value) => value != 0), isTrue);
  });

  test('stepGalaxyParticlesDart updates positions in place', () {
    final particles = Float32List.fromList(<double>[
      0.90,
      0.10,
      0.05,
      0.24,
      -0.55,
      0.40,
      -0.14,
      0.09,
    ]);
    final before = Float32List.fromList(particles);

    stepGalaxyParticlesDart(particles, 2, 1 / 60);

    expect(particles[0], isNot(closeTo(before[0], 1e-6)));
    expect(particles[4], isNot(closeTo(before[4], 1e-6)));
  });

  test('Dart backend reseeds to the requested particle count', () {
    final backend = DartGalaxySimulationBackend(particleCount: 16);
    addTearDown(backend.dispose);

    backend.reseed(
      32,
      config: const GalaxyStepConfig(swirl: 1.5, centerPull: 1.8),
    );

    expect(backend.particleCount, 32);
    expect(backend.particles.length, 32 * galaxyParticleStride);
  });
}
