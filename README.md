# FFI Examples

Flutter learning project for exploring `dart:ffi` through concrete examples, banking-style usages, and a live `Pure Dart vs C via FFI vs Rust via FFI` particle benchmark.

The app depends on the local FFI plugin in `packages/bank_core_ffi`. The plugin exports a small C ABI and the Flutter app calls it through a Dart facade, without leaking raw pointers into the UI. The C implementation is in `packages/bank_core_ffi/src`; the Rust galaxy backend is in `packages/bank_core_ffi/rust`.

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
- `Setup`: installation guide for Flutter, the local FFI plugin, Rust/Cargo, Apple targets, build wiring, and verification commands.
- `Live Calls`: strings, structs, error mapping, and banking-oriented native calls.
- `Usage Map`: where FFI belongs in a BI.ZONE AntiFraud-style client/server architecture.
- `Performance`: selectable galaxy visual layers with three compute backends, measuring step time, tick rate, and particle updates per second.

## Setup

The app now includes a dedicated `Setup` screen with the same commands used to prepare the FFI demo:

- create an app and local `plugin_ffi` package when starting from zero;
- add `bank_core_ffi` as a path dependency;
- install Rust with `rustup` and add Apple targets;
- run the app and verify root/plugin tests;
- understand how `packages/bank_core_ffi/scripts/build_rust_apple.sh` is called from the iOS/macOS podspecs.

## Run

```sh
flutter pub get
flutter run -d macos
```

Rust must be installed for Apple builds because the `Rust FFI` backend is linked from `packages/bank_core_ffi/rust` during the CocoaPods build. The Rust crate uses an optimized dev profile so Debug app runs do not benchmark unoptimized Rust. Install Rust with `rustup`, then add the iOS simulator targets when needed:

```sh
rustup target add aarch64-apple-darwin x86_64-apple-darwin
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

Android and iOS are also configured through the generated FFI plugin packaging. Android currently exposes the Dart and C FFI paths unless a Rust Android cross-build is added.

## Verify

```sh
flutter analyze
flutter test

cd packages/bank_core_ffi
flutter analyze
flutter test
```

The plugin tests compile `src/bank_core_ffi.c` into a temporary test dylib so the VM can exercise the real FFI calls without requiring a full Flutter app bundle. When Cargo is installed, the test helper also builds and force-loads `rust/` so the Rust galaxy symbols come from Rust. Without Cargo, the Rust-specific test is skipped instead of silently treating C as Rust.

Local packaging check performed in this pass:

- `flutter build macos --debug`

Additional platform checks, when the local toolchains are available:

- `flutter build apk --debug`
- `flutter build ios --debug --simulator`

Linux and Windows plugin build files are present from the `plugin_ffi` template, but final builds require those platform toolchains.
