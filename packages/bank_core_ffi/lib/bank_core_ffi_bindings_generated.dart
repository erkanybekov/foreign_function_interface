// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// FFI bindings for the small educational C ABI in src/bank_core_ffi.h.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

final class BankTransactionRiskInputNative extends ffi.Struct {
  @ffi.Int32()
  external int amount_cents;

  @ffi.Int32()
  external int account_age_days;

  @ffi.Int32()
  external int failed_attempts_24h;

  @ffi.Int32()
  external int foreign_country;

  @ffi.Int32()
  external int night_time;
}

final class BankRiskScoreNative extends ffi.Struct {
  @ffi.Int32()
  external int score;

  @ffi.Int32()
  external int decision;

  @ffi.Int32()
  external int reason_flags;
}

class BankCoreFfiBindings {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  BankCoreFfiBindings(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  BankCoreFfiBindings.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  int bank_add(int a, int b) {
    return _bank_add(a, b);
  }

  late final _bank_addPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Int32, ffi.Int32)>>(
        'bank_add',
      );
  late final _bank_add = _bank_addPtr.asFunction<int Function(int, int)>();

  int bank_validate_pan(ffi.Pointer<ffi.Char> pan) {
    return _bank_validate_pan(pan);
  }

  late final _bank_validate_panPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<ffi.Char>)>>(
        'bank_validate_pan',
      );
  late final _bank_validate_pan =
      _bank_validate_panPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  int bank_validate_iban(ffi.Pointer<ffi.Char> iban) {
    return _bank_validate_iban(iban);
  }

  late final _bank_validate_ibanPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<ffi.Char>)>>(
        'bank_validate_iban',
      );
  late final _bank_validate_iban =
      _bank_validate_ibanPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  int bank_score_transaction(
    ffi.Pointer<BankTransactionRiskInputNative> input,
    ffi.Pointer<BankRiskScoreNative> output,
  ) {
    return _bank_score_transaction(input, output);
  }

  late final _bank_score_transactionPtr = _lookup<
    ffi.NativeFunction<
      ffi.Int32 Function(
        ffi.Pointer<BankTransactionRiskInputNative>,
        ffi.Pointer<BankRiskScoreNative>,
      )
    >
  >('bank_score_transaction');
  late final _bank_score_transaction =
      _bank_score_transactionPtr
          .asFunction<
            int Function(
              ffi.Pointer<BankTransactionRiskInputNative>,
              ffi.Pointer<BankRiskScoreNative>,
            )
          >();

  int bank_update_galaxy_particles(
    ffi.Pointer<ffi.Float> particles,
    int particle_count,
    double dt_seconds,
    double center_pull,
    double swirl,
    double damping,
    double escape_radius,
    double respawn_radius,
  ) {
    return _bank_update_galaxy_particles(
      particles,
      particle_count,
      dt_seconds,
      center_pull,
      swirl,
      damping,
      escape_radius,
      respawn_radius,
    );
  }

  late final _bank_update_galaxy_particlesPtr = _lookup<
    ffi.NativeFunction<
      ffi.Int32 Function(
        ffi.Pointer<ffi.Float>,
        ffi.Int32,
        ffi.Float,
        ffi.Float,
        ffi.Float,
        ffi.Float,
        ffi.Float,
        ffi.Float,
      )
    >
  >('bank_update_galaxy_particles');
  late final _bank_update_galaxy_particles = _bank_update_galaxy_particlesPtr
      .asFunction<
        int Function(
          ffi.Pointer<ffi.Float>,
          int,
          double,
          double,
          double,
          double,
          double,
          double,
        )
      >(isLeaf: true);

  ffi.Pointer<ffi.Char> bank_error_message(int code) {
    return _bank_error_message(code);
  }

  late final _bank_error_messagePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function(ffi.Int32)>>(
        'bank_error_message',
      );
  late final _bank_error_message =
      _bank_error_messagePtr.asFunction<ffi.Pointer<ffi.Char> Function(int)>();
}
