# Bank FFI Lab

Flutter learning project for exploring `dart:ffi` from the C ABI up through banking-style use cases and a live `Pure Dart vs C via FFI` particle benchmark.

The app depends on the local FFI plugin in `packages/bank_core_ffi`. The plugin exports a small C API and the Flutter app calls it through a Dart facade, without leaking raw pointers into the UI.

## What The Demo Covers

- Scalar native calls: `bank_add(int32_t, int32_t)`.
- Native string inputs: PAN/Luhn and IBAN MOD-97 validation through `char*`.
- Native structs: transaction risk input and output structs allocated by Dart.
- Error mapping: negative native error codes become Dart exceptions/messages.
- Batched native compute: a calm cosmos particle simulation where Flutter keeps the renderer and the compute backend switches between pure Dart and C via FFI.
- Banking guardrails: no custom crypto, no PII logging, and FFI as a wrapper for audited native SDKs or libraries.

## App Screens

- `Bank Lab`: strings, structs, error mapping, and banking-oriented FFI examples.
- `Cosmos Benchmark`: the same visual layer with two compute backends, measuring step time, tick rate, and particle updates per second.

## Run

```sh
flutter pub get
flutter run -d macos
```

Android and iOS are also configured through the generated FFI plugin packaging.

## Verify

```sh
flutter analyze
flutter test

cd packages/bank_core_ffi
flutter analyze
flutter test
```

The plugin tests compile `src/bank_core_ffi.c` into a temporary test dylib so the VM can exercise the real FFI calls without requiring a full Flutter app bundle.

Local packaging checks performed on this machine:

- `flutter build macos --debug`
- `flutter build apk --debug`
- `flutter build ios --debug --simulator`

Linux and Windows plugin build files are present from the `plugin_ffi` template, but final builds require those platform toolchains.
