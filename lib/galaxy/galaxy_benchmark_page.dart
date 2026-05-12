/// Particle benchmark UI comparing Dart, C FFI, and Rust FFI backends.
///
/// Split into `galaxy_benchmark/` parts so private widgets stay library-private
/// without renaming. [GalaxyBenchmarkPage] is the entry widget.
import 'dart:math' as math;
import 'dart:ui' show FontFeature, FragmentProgram, lerpDouble;

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../platform_adaptive.dart';
import 'galaxy_simulation.dart';

part 'galaxy_benchmark/benchmark_models.dart';
part 'galaxy_benchmark/benchmark_format.dart';
part 'galaxy_benchmark/benchmark_labels.dart';
part 'galaxy_benchmark/benchmark_visual_effect_info.dart';
part 'galaxy_benchmark/benchmark_scene.dart';
part 'galaxy_benchmark/benchmark_chrome.dart';
part 'galaxy_benchmark/benchmark_verdict_ui.dart';
part 'galaxy_benchmark/benchmark_visual_panels.dart';
part 'galaxy_benchmark/benchmark_overview_scene.dart';
part 'galaxy_benchmark/benchmark_controls.dart';
part 'galaxy_benchmark/benchmark_notes.dart';
part 'galaxy_benchmark/benchmark_painter.dart';
part 'galaxy_benchmark/benchmark_page.dart';
