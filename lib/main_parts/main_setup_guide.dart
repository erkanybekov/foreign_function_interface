part of '../main.dart';

// Setup Guide tab: project layout, Rust, run commands, troubleshooting.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// Second tab: how to build and run this repo (layout, Rust, Apple, verification, troubleshooting).
class SetupGuidePage extends StatelessWidget {
  const SetupGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      title: 'Setup Guide',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _SetupHeroPanel(),
          SizedBox(height: 12),
          _SetupProjectMapPanel(),
          SizedBox(height: 12),
          _SetupFromZeroPanel(),
          SizedBox(height: 12),
          _SetupRustPanel(),
          SizedBox(height: 12),
          _SetupRunPanel(),
          SizedBox(height: 12),
          _SetupAppleBuildPanel(),
          SizedBox(height: 12),
          _SetupVerifyPanel(),
          SizedBox(height: 12),
          _SetupTroubleshootingPanel(),
        ],
      ),
    );
  }
}

class _SetupHeroPanel extends StatelessWidget {
  const _SetupHeroPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.terminal,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'How to setup this FFI demo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This is the installation guide for the repo: Flutter app, local FFI plugin, C ABI, and the Rust galaxy backend used by the performance screen.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _GuidePill(icon: Icons.flutter_dash, text: 'Flutter app'),
              _GuidePill(icon: Icons.memory, text: 'C FFI plugin'),
              _GuidePill(icon: Icons.construction, text: 'Rust backend'),
              _GuidePill(icon: Icons.fact_check, text: 'Verify commands'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupProjectMapPanel extends StatelessWidget {
  const _SetupProjectMapPanel();

  static const List<({IconData icon, String title, String body})> items = [
    (
      icon: Icons.extension,
      title: 'Local FFI plugin',
      body: 'packages/bank_core_ffi is a Flutter ffiPlugin dependency.',
    ),
    (
      icon: Icons.hub,
      title: 'C ABI',
      body: 'src/bank_core_ffi.h and .c export stable C symbols for Dart.',
    ),
    (
      icon: Icons.code,
      title: 'Dart facade',
      body: 'lib/bank_core_ffi.dart hides Pointer, calloc, and lookup details.',
    ),
    (
      icon: Icons.construction,
      title: 'Rust crate',
      body: 'rust/src/lib.rs exports extra galaxy benchmark symbols.',
    ),
    (
      icon: Icons.apple,
      title: 'Apple build script',
      body: 'scripts/build_rust_apple.sh builds Rust static libraries.',
    ),
    (
      icon: Icons.settings,
      title: 'Podspec hook',
      body:
          'iOS and macOS podspecs run the Rust build during CocoaPods builds.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideGridPanel(title: 'What was set up', children: items);
  }
}

class _SetupFromZeroPanel extends StatelessWidget {
  const _SetupFromZeroPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Starting from zero',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'These are the commands a developer would use to create the same shape: an app plus a local FFI plugin package.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Create app and FFI plugin',
                        body:
                            'Use this only when bootstrapping a new project. This repo already contains the generated app and plugin.',
                        code: '''
flutter create foreign_function_interface
cd foreign_function_interface
flutter create --template=plugin_ffi packages/bank_core_ffi''',
                        maxLines: 5,
                      ),
                      _SetupCommandCard(
                        title: 'Wire the local plugin',
                        body:
                            'Add the path dependency to the app pubspec, then fetch dependencies.',
                        code: '''
dependencies:
  bank_core_ffi:
    path: packages/bank_core_ffi
  ffi: ^2.2.0''',
                        maxLines: 6,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupRustPanel extends StatelessWidget {
  const _SetupRustPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Install Rust for the Rust FFI backend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Apple builds need Cargo because the Rust static library is built during the macOS/iOS CocoaPods phase.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Install rustup and Cargo',
                        body:
                            'Install Rust, load Cargo into the current shell, then confirm the toolchain is visible.',
                        code: r'''
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo --version
rustup --version''',
                        maxLines: 6,
                      ),
                      _SetupCommandCard(
                        title: 'Add Apple targets',
                        body:
                            'macOS needs Darwin targets. iOS simulator builds also need iOS and simulator targets.',
                        code: '''
rustup target add aarch64-apple-darwin x86_64-apple-darwin
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios''',
                        maxLines: 4,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupRunPanel extends StatelessWidget {
  const _SetupRunPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Run this repo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'After Rust is available, Flutter can fetch the local plugin and run the app. The first Apple build also compiles the Rust crate.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'Get packages',
                        body:
                            'Run from the repository root so the app resolves packages/bank_core_ffi.',
                        code: 'flutter pub get',
                      ),
                      _SetupCommandCard(
                        title: 'Run the desktop app',
                        body:
                            'macOS is the fastest path for trying all screens locally.',
                        code: 'flutter run -d macos',
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupAppleBuildPanel extends StatelessWidget {
  const _SetupAppleBuildPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'How the Rust build is connected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'The app does not ask developers to run Cargo manually on every build. The iOS and macOS podspecs call the script below, and that script builds libbank_core_ffi_rust.a for the active Apple architecture.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const _CodeBlock(
            code: '''
packages/bank_core_ffi/scripts/build_rust_apple.sh
packages/bank_core_ffi/ios/bank_core_ffi.podspec
packages/bank_core_ffi/macos/bank_core_ffi.podspec
packages/bank_core_ffi/rust/Cargo.toml''',
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          const _GuideTile(
            icon: Icons.tune,
            title: 'Debug Rust is optimized',
            body:
                'rust/Cargo.toml sets profile.dev opt-level = 3 so Debug app runs do not benchmark unoptimized Rust.',
          ),
        ],
      ),
    );
  }
}

class _SetupVerifyPanel extends StatelessWidget {
  const _SetupVerifyPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Verify the setup',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Use these checks before demoing the app or changing native bindings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    const <Widget>[
                      _SetupCommandCard(
                        title: 'App checks',
                        body:
                            'Analyze and run the widget/unit tests from the root.',
                        code: '''
flutter analyze
flutter test''',
                        maxLines: 4,
                      ),
                      _SetupCommandCard(
                        title: 'Plugin checks',
                        body:
                            'The plugin tests compile C and use Cargo when it is installed.',
                        code: '''
cd packages/bank_core_ffi
flutter analyze
flutter test''',
                        maxLines: 5,
                      ),
                      _SetupCommandCard(
                        title: 'Apple packaging check',
                        body:
                            'This exercises CocoaPods, the script phase, C, and Rust linking.',
                        code: 'flutter build macos --debug',
                      ),
                      _SetupCommandCard(
                        title: 'Regenerate bindings after ABI changes',
                        body:
                            'Only needed when src/bank_core_ffi.h changes and generated Dart bindings must be refreshed.',
                        code: '''
cd packages/bank_core_ffi
dart run ffigen --config ffigen.yaml''',
                        maxLines: 4,
                      ),
                    ].map((card) => SizedBox(width: width, child: card)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupTroubleshootingPanel extends StatelessWidget {
  const _SetupTroubleshootingPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final width =
              narrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.build_circle,
                  title: 'If Cargo is not found',
                  items: <String>[
                    r'Run source "$HOME/.cargo/env" or reopen the terminal.',
                    'Check cargo --version before running Flutter again.',
                    r'Make sure Xcode build phases can see $HOME/.cargo/bin.',
                    'The build script prepends common Cargo/Homebrew paths.',
                  ],
                ),
              ),
              SizedBox(
                width: width,
                child: const _DecisionColumn(
                  icon: Icons.devices,
                  title: 'Platform notes',
                  items: <String>[
                    'macOS and iOS link C plus Rust through CocoaPods.',
                    'Android currently exposes the Dart and C FFI paths.',
                    'Linux and Windows files exist, but need local toolchains.',
                    'Flutter web cannot use dart:ffi.',
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupCommandCard extends StatelessWidget {
  const _SetupCommandCard({
    required this.title,
    required this.body,
    required this.code,
    this.maxLines = 3,
  });

  final String title;
  final String body;
  final String code;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 10),
            _CodeBlock(code: code, maxLines: maxLines),
          ],
        ),
      ),
    );
  }
}
