# FFI Examples

Flutter learning project for exploring `dart:ffi` through concrete examples, banking-style usages, and a live `Pure Dart vs C via FFI vs Rust via FFI` particle benchmark.

The app depends on the local FFI plugin in `packages/bank_core_ffi`. The plugin exports a small C ABI and the Flutter app calls it through a Dart facade, without leaking raw pointers into the UI.

## What The Demo Covers

- Scalar native calls: `bank_add(int32_t, int32_t)`.
- Native string inputs: PAN/Luhn and IBAN MOD-97 validation through `char*`.
- Native structs: transaction risk input and output structs allocated by Dart.
- Error mapping: negative native error codes become Dart exceptions/messages.
- FFI mental model: Flutter UI -> Dart facade -> FFI boundary -> native library.
- FFI implementation basics: C ABI export, Dart bindings, facade, native memory ownership, and compact code examples.
- FFI best practices: generated bindings, batched calls, pointer ownership, release benchmarking, and no PII logging.
- Batched native compute: an orbiting galaxy particle simulation where Flutter keeps the renderer and the compute backend switches between pure Dart, C via FFI, and Rust via FFI.
- Visual presets: Nebula, Star Warp, Gravitational Lens, Aurora, Risk Heatmap, and Device Fingerprint Field layers.
- Banking guardrails: no custom crypto, no PII logging, and FFI as a wrapper for audited native SDKs or libraries.

## App Screens

- `Examples`: concrete FFI examples, their Dart usage code, native boundary code, product usage, and fit.
- `Live Calls`: strings, structs, error mapping, and banking-oriented native calls.
- `Usage Map`: where FFI belongs in a BI.ZONE AntiFraud-style client/server architecture.
- `Performance`: selectable galaxy visual layers with three compute backends, measuring step time, tick rate, and particle updates per second.

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

Local packaging check performed in this pass:

- `flutter build macos --debug`

Additional platform checks, when the local toolchains are available:

- `flutter build apk --debug`
- `flutter build ios --debug --simulator`

Linux and Windows plugin build files are present from the `plugin_ffi` template, but final builds require those platform toolchains.
