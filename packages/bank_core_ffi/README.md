# bank_core_ffi

Local Flutter FFI plugin used by the Bank FFI Lab app and its cosmos benchmark.

The native implementation lives in `src/bank_core_ffi.c` and is exposed through `src/bank_core_ffi.h`. The Rust galaxy backend lives in `rust/src/lib.rs` and exports the same C ABI symbols for the Rust benchmark path. The Dart facade in `lib/bank_core_ffi.dart` owns all pointer allocation/freeing and exposes a small banking-oriented API:

```dart
final core = BankCoreFfi();

core.add(1200, 37);
core.isValidPan('4111 1111 1111 1111');
core.isValidIban('GB82 WEST 1234 5698 7654 32');
core.scoreTransaction(
  const TransactionRiskInput(
    amountCents: 1250000,
    accountAgeDays: 24,
    failedAttempts24h: 3,
    foreignCountry: true,
    nightTime: true,
  ),
);

final particleBuffer = calloc<Float>(1536 * galaxyParticleStride);
core.updateGalaxyParticles(
  particles: particleBuffer,
  particleCount: 1536,
  dtSeconds: 1 / 60,
);
```

## Native ABI

- `bank_add` returns a scalar `int32_t`.
- `bank_validate_pan` and `bank_validate_iban` receive Dart-allocated UTF-8 strings as `char*`.
- `bank_score_transaction` receives a Dart-allocated input struct and fills a Dart-allocated output struct.
- `bank_update_galaxy_particles` updates a whole `float*` particle buffer in one FFI call.
- `bank_rust_backend_version` is exported only by the Rust crate, so Dart can detect whether the Rust backend is really linked.
- `bank_update_galaxy_particles_rust` and `bank_update_galaxy_particles_rust_batched` are implemented in Rust. The C file has no implicit Rust fallback.
- `rust/Cargo.toml` intentionally optimizes the dev profile; otherwise Flutter Debug builds would measure Cargo's unoptimized Rust profile rather than Rust FFI performance.
- Negative return codes are native failures; the Dart facade maps them to `BankCoreFfiException`.

Native code must not store Dart-owned pointers after a function returns.

## Test

```sh
flutter analyze
flutter test
```

`flutter test` does not package the plugin framework like a full app build. The tests compile the C source into a temporary dynamic library and pass that library to `BankCoreFfi`, so validation, struct marshalling, error mapping, and repeated allocation/free cycles still exercise real native code. If `cargo` is on PATH, the test helper also builds `rust/` and force-loads those Rust symbols into the temporary library. If Cargo is missing, the Rust-specific test is skipped instead of using a C fallback.
