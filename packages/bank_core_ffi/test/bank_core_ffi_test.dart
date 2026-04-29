import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BankCoreFfi core;

  setUpAll(() async {
    core = BankCoreFfi(library: await _compileTestLibrary());
  });

  test('calls scalar native function', () {
    expect(core.add(1200, 37), 1237);
  });

  test('validates PAN with Luhn in native code', () {
    expect(core.isValidPan('4111 1111 1111 1111'), isTrue);
    expect(core.isValidPan('4111 1111 1111 1112'), isFalse);
  });

  test('validates IBAN with MOD-97 in native code', () {
    expect(core.isValidIban('GB82 WEST 1234 5698 7654 32'), isTrue);
    expect(core.isValidIban('GB82 WEST 1234 5698 7654 33'), isFalse);
  });

  test('fills risk score output struct', () {
    final score = core.scoreTransaction(
      const TransactionRiskInput(
        amountCents: 2500000,
        accountAgeDays: 12,
        failedAttempts24h: 3,
        foreignCountry: true,
        nightTime: true,
      ),
    );

    expect(score.score, 100);
    expect(score.decision, RiskDecision.block);
    expect(
      score.flags,
      containsAll(<RiskFlag>[
        RiskFlag.highAmount,
        RiskFlag.newAccount,
        RiskFlag.failedAttempts,
        RiskFlag.foreignCountry,
        RiskFlag.nightTime,
      ]),
    );
  });

  test('maps native error codes into Dart exceptions', () {
    expect(
      () => core.scoreTransaction(
        const TransactionRiskInput(
          amountCents: -1,
          accountAgeDays: 12,
          failedAttempts24h: 0,
          foreignCountry: false,
          nightTime: false,
        ),
      ),
      throwsA(isA<BankCoreFfiException>()),
    );
    expect(
      core.nativeErrorMessage(-2),
      'native argument is outside the accepted range',
    );
  });

  test('survives repeated string allocation and free cycles', () {
    for (var index = 0; index < 100; index++) {
      expect(core.isValidPan('4111 1111 1111 1111'), isTrue);
      expect(core.isValidIban('GB82 WEST 1234 5698 7654 32'), isTrue);
    }
  });

  test('updates a batched galaxy particle buffer in native code', () {
    final particles = calloc<ffi.Float>(galaxyParticleStride * 2);
    addTearDown(() => calloc.free(particles));
    final view = particles.asTypedList(galaxyParticleStride * 2);
    view.setAll(0, <double>[0.9, 0.1, 0.0, 0.2, 0.5, -0.6, 0.1, -0.2]);

    core.updateGalaxyParticles(
      particles: particles,
      particleCount: 2,
      dtSeconds: 1 / 60,
    );

    expect(view[0], isNot(closeTo(0.9, 1e-6)));
    expect(view[4], isNot(closeTo(0.5, 1e-6)));
  });

  test(
    'native galaxy step stays close to the Dart reference implementation',
    () {
      const config = GalaxyStepConfig(
        centerPull: 1.75,
        swirl: 1.45,
        damping: 0.993,
        escapeRadius: 1.25,
        respawnRadius: 0.95,
      );
      final reference = Float32List.fromList(<double>[
        0.90,
        0.10,
        0.05,
        0.24,
        -0.55,
        0.40,
        -0.14,
        0.09,
        0.22,
        -0.74,
        0.17,
        -0.12,
      ]);
      final native = calloc<ffi.Float>(reference.length);
      addTearDown(() => calloc.free(native));
      final nativeView = native.asTypedList(reference.length);
      nativeView.setAll(0, reference);

      core.updateGalaxyParticles(
        particles: native,
        particleCount: 3,
        dtSeconds: 1 / 60,
        config: config,
      );
      _stepGalaxyParticlesReference(reference, 3, 1 / 60, config: config);

      for (var index = 0; index < reference.length; index++) {
        expect(nativeView[index], closeTo(reference[index], 1e-4));
      }
    },
  );

  test('native batched galaxy step matches repeated Dart reference steps', () {
    const config = GalaxyStepConfig(centerPull: 1.7, swirl: 1.4);
    final reference = Float32List.fromList(<double>[
      0.80,
      0.20,
      0.05,
      0.18,
      -0.42,
      0.58,
      -0.08,
      0.12,
    ]);
    final native = calloc<ffi.Float>(reference.length);
    addTearDown(() => calloc.free(native));
    final nativeView = native.asTypedList(reference.length);
    nativeView.setAll(0, reference);

    core.updateGalaxyParticlesBatched(
      particles: native,
      particleCount: 2,
      dtSeconds: 1 / 60,
      substeps: 4,
      config: config,
    );
    for (var step = 0; step < 4; step++) {
      _stepGalaxyParticlesReference(reference, 2, 1 / 60, config: config);
    }

    for (var index = 0; index < reference.length; index++) {
      expect(nativeView[index], closeTo(reference[index], 1e-4));
    }
  });
}

Future<ffi.DynamicLibrary> _compileTestLibrary() async {
  final sourcePath = _join(Directory.current.path, 'src', 'bank_core_ffi.c');
  final outputDirectory = Directory.systemTemp.createTempSync(
    'bank_core_ffi_test_',
  );
  final outputPath = _join(
    outputDirectory.path,
    Platform.isMacOS
        ? 'libbank_core_ffi_test.dylib'
        : Platform.isLinux
        ? 'libbank_core_ffi_test.so'
        : 'bank_core_ffi_test.dll',
  );

  if (Platform.isWindows) {
    throw UnsupportedError(
      'The FFI unit test helper currently compiles the C library with cc on '
      'macOS/Linux. Use the Flutter app build to validate Windows packaging.',
    );
  }

  final arguments =
      Platform.isMacOS
          ? <String>['-dynamiclib', '-o', outputPath, sourcePath]
          : <String>['-shared', '-fPIC', '-o', outputPath, sourcePath];
  final result = await Process.run('cc', arguments);
  if (result.exitCode != 0) {
    fail(
      'Failed to compile test native library.\n'
      'stdout:\n${result.stdout}\n'
      'stderr:\n${result.stderr}',
    );
  }

  return ffi.DynamicLibrary.open(outputPath);
}

String _join(String part1, String part2, [String? part3]) {
  final separator = Platform.pathSeparator;
  return <String>[part1, part2, if (part3 != null) part3].join(separator);
}

const double _galaxySoftening = 0.025;
const double _galaxyCenterEpsilon = 0.0016;

double _fractional(double value) => value - value.floorToDouble();

void _respawnReferenceParticle(
  Float32List particles,
  int particleIndex, {
  required GalaxyStepConfig config,
}) {
  final offset = particleIndex * galaxyParticleStride;
  final angleSeed = _fractional((particleIndex + 1) * 0.61803398875);
  final radiusSeed = _fractional((particleIndex + 1) * 0.75487766625);
  final angle = angleSeed * math.pi * 2.0;
  final radius = config.respawnRadius * (0.32 + radiusSeed * 0.68);
  final sinAngle = math.sin(angle);
  final cosAngle = math.cos(angle);
  final tangentialSpeed = config.swirl * (0.22 + radius * 0.4);

  particles[offset] = cosAngle * radius;
  particles[offset + 1] = sinAngle * radius;
  particles[offset + 2] = -sinAngle * tangentialSpeed;
  particles[offset + 3] = cosAngle * tangentialSpeed;
}

void _stepGalaxyParticlesReference(
  Float32List particles,
  int particleCount,
  double dtSeconds, {
  required GalaxyStepConfig config,
}) {
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
      _respawnReferenceParticle(particles, index, config: config);
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
