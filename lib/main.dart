/// Demo Flutter application for FFI in a banking context.
///
/// This library is intentionally split across `main_parts/*.dart` using [part]
/// directives so private widgets (prefixed with `_`) stay in one library without
/// renaming half the codebase.
///
/// **Tabs (see [_HomeShellState])**
/// - **Examples** — conceptual FFI guide and links into other tabs.
/// - **Setup** — how the repo is wired (C/Rust, pods, run commands).
/// - **Live Calls** — interactive calls into [BankCoreFfi] via [BankLabService].
/// - **Usage Map** — AntiFraud / client FFI fit (narrative only).
/// - **Performance** — galaxy particle benchmark (see [GalaxyBenchmarkPage]).
///
/// For tests, [MyApp] accepts optional [BankLabService] and [BankCoreFfi] overrides.
library;
import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'galaxy/galaxy_benchmark_page.dart';
import 'platform_adaptive.dart';

part 'main_parts/main_app_bootstrap.dart';
part 'main_parts/main_home_shell.dart';
part 'main_parts/main_home_navigation.dart';
part 'main_parts/main_ffi_guide_page.dart';
part 'main_parts/main_ffi_guide_panels.dart';
part 'main_parts/main_setup_guide.dart';
part 'main_parts/main_guide_grid.dart';
part 'main_parts/main_antifraud.dart';
part 'main_parts/main_bank_lab_page.dart';
part 'main_parts/main_bank_live_panels.dart';
part 'main_parts/main_widgets_and_formatting.dart';
