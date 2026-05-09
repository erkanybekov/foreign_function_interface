import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'bank_core_ffi_bindings_generated.dart';

const String _libName = 'bank_core_ffi';
const int galaxyParticleStride = 4;

ffi.DynamicLibrary _openBankCoreLibrary() {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}

enum RiskDecision { approve, review, block }

enum RiskFlag {
  highAmount,
  newAccount,
  failedAttempts,
  foreignCountry,
  nightTime,
}

class TransactionRiskInput {
  const TransactionRiskInput({
    required this.amountCents,
    required this.accountAgeDays,
    required this.failedAttempts24h,
    required this.foreignCountry,
    required this.nightTime,
  });

  final int amountCents;
  final int accountAgeDays;
  final int failedAttempts24h;
  final bool foreignCountry;
  final bool nightTime;
}

class RiskScore {
  const RiskScore({
    required this.score,
    required this.decision,
    required this.flags,
  });

  final int score;
  final RiskDecision decision;
  final Set<RiskFlag> flags;
}

class BankCoreFfiException implements Exception {
  const BankCoreFfiException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'BankCoreFfiException($code): $message';
}

class GalaxyStepConfig {
  const GalaxyStepConfig({
    this.centerPull = 0.08,
    this.swirl = 0.18,
    this.damping = 0.999,
    this.escapeRadius = 1.18,
    this.respawnRadius = 1.08,
  });

  final double centerPull;
  final double swirl;
  final double damping;
  final double escapeRadius;
  final double respawnRadius;
}

class BankCoreFfi {
  BankCoreFfi({BankCoreFfiBindings? bindings, ffi.DynamicLibrary? library})
    : assert(
        bindings == null || library == null,
        'Pass either bindings or library, not both.',
      ),
      _bindings =
          bindings ?? BankCoreFfiBindings(library ?? _openBankCoreLibrary());

  final BankCoreFfiBindings _bindings;

  int add(int a, int b) => _bindings.bank_add(a, b);

  bool isValidPan(String pan) {
    final pointer = pan.toNativeUtf8(allocator: calloc);
    try {
      final result = _bindings.bank_validate_pan(pointer.cast<ffi.Char>());
      _checkResult(result);
      return result == 1;
    } finally {
      calloc.free(pointer);
    }
  }

  bool isValidIban(String iban) {
    final pointer = iban.toNativeUtf8(allocator: calloc);
    try {
      final result = _bindings.bank_validate_iban(pointer.cast<ffi.Char>());
      _checkResult(result);
      return result == 1;
    } finally {
      calloc.free(pointer);
    }
  }

  RiskScore scoreTransaction(TransactionRiskInput input) {
    final nativeInput = calloc<BankTransactionRiskInputNative>();
    final nativeOutput = calloc<BankRiskScoreNative>();
    try {
      nativeInput.ref
        ..amount_cents = input.amountCents
        ..account_age_days = input.accountAgeDays
        ..failed_attempts_24h = input.failedAttempts24h
        ..foreign_country = input.foreignCountry ? 1 : 0
        ..night_time = input.nightTime ? 1 : 0;

      final result = _bindings.bank_score_transaction(
        nativeInput,
        nativeOutput,
      );
      _checkResult(result);

      return RiskScore(
        score: nativeOutput.ref.score,
        decision: _decisionFromNative(nativeOutput.ref.decision),
        flags: _flagsFromNative(nativeOutput.ref.reason_flags),
      );
    } finally {
      calloc.free(nativeInput);
      calloc.free(nativeOutput);
    }
  }

  String nativeErrorMessage(int code) {
    final pointer = _bindings.bank_error_message(code);
    return pointer.cast<Utf8>().toDartString();
  }

  void updateGalaxyParticles({
    required ffi.Pointer<ffi.Float> particles,
    required int particleCount,
    required double dtSeconds,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final result = _bindings.bank_update_galaxy_particles(
      particles,
      particleCount,
      dtSeconds,
      config.centerPull,
      config.swirl,
      config.damping,
      config.escapeRadius,
      config.respawnRadius,
    );
    _checkResult(result);
  }

  void updateGalaxyParticlesBatched({
    required ffi.Pointer<ffi.Float> particles,
    required int particleCount,
    required double dtSeconds,
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final result = _bindings.bank_update_galaxy_particles_batched(
      particles,
      particleCount,
      dtSeconds,
      config.centerPull,
      config.swirl,
      config.damping,
      config.escapeRadius,
      config.respawnRadius,
      substeps,
    );
    _checkResult(result);
  }

  void updateGalaxyParticlesRust({
    required ffi.Pointer<ffi.Float> particles,
    required int particleCount,
    required double dtSeconds,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final result = _bindings.bank_update_galaxy_particles_rust(
      particles,
      particleCount,
      dtSeconds,
      config.centerPull,
      config.swirl,
      config.damping,
      config.escapeRadius,
      config.respawnRadius,
    );
    _checkResult(result);
  }

  void updateGalaxyParticlesRustBatched({
    required ffi.Pointer<ffi.Float> particles,
    required int particleCount,
    required double dtSeconds,
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final result = _bindings.bank_update_galaxy_particles_rust_batched(
      particles,
      particleCount,
      dtSeconds,
      config.centerPull,
      config.swirl,
      config.damping,
      config.escapeRadius,
      config.respawnRadius,
      substeps,
    );
    _checkResult(result);
  }

  void _checkResult(int code) {
    if (code >= 0) {
      return;
    }

    throw BankCoreFfiException(code, nativeErrorMessage(code));
  }

  RiskDecision _decisionFromNative(int decision) {
    return switch (decision) {
      0 => RiskDecision.approve,
      1 => RiskDecision.review,
      2 => RiskDecision.block,
      _ =>
        throw BankCoreFfiException(
          decision,
          'native risk decision is outside the accepted range',
        ),
    };
  }

  Set<RiskFlag> _flagsFromNative(int flags) {
    return <RiskFlag>{
      if ((flags & 1) != 0) RiskFlag.highAmount,
      if ((flags & 2) != 0) RiskFlag.newAccount,
      if ((flags & 4) != 0) RiskFlag.failedAttempts,
      if ((flags & 8) != 0) RiskFlag.foreignCountry,
      if ((flags & 16) != 0) RiskFlag.nightTime,
    };
  }
}
