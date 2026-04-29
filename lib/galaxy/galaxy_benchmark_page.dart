import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show FontFeature, lerpDouble;

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'galaxy_simulation.dart';

const List<int> galaxyComputeParticlePresets = <int>[8192, 32768, 65536];
const List<int> galaxySubstepPresets = <int>[1, 4, 8];
const int galaxyVisibleParticleLimit = 3072;

enum GalaxyBenchmarkViewMode { compare, single }

typedef GalaxyBenchmarkBackendBuilder =
    GalaxySimulationBackend Function(
      GalaxyComputeBackend kind,
      int particleCount,
      GalaxyStepConfig config,
      BankCoreFfi? core,
    );

class GalaxyBenchmarkPage extends StatefulWidget {
  const GalaxyBenchmarkPage({super.key, this.core, this.backendBuilder});

  final BankCoreFfi? core;
  final GalaxyBenchmarkBackendBuilder? backendBuilder;

  @override
  State<GalaxyBenchmarkPage> createState() => _GalaxyBenchmarkPageState();
}

class _GalaxyBenchmarkPageState extends State<GalaxyBenchmarkPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ValueNotifier<int> _painterTick;
  late final Map<GalaxyComputeBackend, _BenchmarkSceneState> _scenes;
  BankCoreFfi? _core;

  GalaxyBenchmarkViewMode _viewMode = GalaxyBenchmarkViewMode.compare;
  GalaxyComputeBackend _singleBackendKind = GalaxyComputeBackend.dart;
  int _particleCount = 32768;
  int _substepsPerSample = 4;
  double _timeScale = 0.8;
  double _swirl = 0.18;
  double _centerPull = 0.08;
  double _smoothedFrameMicros = 16667;
  int _sampleCount = 0;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _painterTick = ValueNotifier<int>(0);
    _scenes = <GalaxyComputeBackend, _BenchmarkSceneState>{
      for (final kind in GalaxyComputeBackend.values)
        kind: _createScene(kind, particleCount: _particleCount),
    };
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _painterTick.dispose();
    for (final scene in _scenes.values) {
      scene.dispose();
    }
    super.dispose();
  }

  BankCoreFfi get _resolvedCore => _core ??= widget.core ?? BankCoreFfi();

  GalaxyStepConfig get _stepConfig => GalaxyStepConfig(
    centerPull: _centerPull,
    swirl: _swirl,
    damping: 0.999,
    escapeRadius: 1.18,
    respawnRadius: 1.08,
  );

  Iterable<_BenchmarkSceneState> get _activeScenes {
    return switch (_viewMode) {
      GalaxyBenchmarkViewMode.compare => _scenes.values,
      GalaxyBenchmarkViewMode.single => <_BenchmarkSceneState>[
        _scenes[_singleBackendKind]!,
      ],
    };
  }

  _BenchmarkSceneState _createScene(
    GalaxyComputeBackend kind, {
    required int particleCount,
  }) {
    final builder = widget.backendBuilder;
    if (builder != null) {
      return _BenchmarkSceneState(
        kind: kind,
        backend: builder(kind, particleCount, _stepConfig, widget.core),
      );
    }

    return _BenchmarkSceneState(
      kind: kind,
      backend: switch (kind) {
        GalaxyComputeBackend.dart => DartGalaxySimulationBackend(
          particleCount: particleCount,
          config: _stepConfig,
        ),
        GalaxyComputeBackend.cFfi => FfiGalaxySimulationBackend(
          core: _resolvedCore,
          particleCount: particleCount,
          config: _stepConfig,
        ),
      },
    );
  }

  void _reseedAllScenes() {
    for (final scene in _scenes.values) {
      scene.reseed(_particleCount, config: _stepConfig);
    }
    _resetMetrics();
  }

  void _resetMetrics() {
    _lastElapsed = null;
    _sampleCount = 0;
    _smoothedFrameMicros = 16667;
    for (final scene in _scenes.values) {
      scene.resetMetrics();
    }
  }

  void _handleTick(Duration elapsed) {
    final previousElapsed = _lastElapsed;
    _lastElapsed = elapsed;
    if (previousElapsed == null) {
      return;
    }

    final rawFrameMicros =
        (elapsed - previousElapsed).inMicroseconds.toDouble();
    if (rawFrameMicros <= 0) {
      return;
    }

    final dtSeconds =
        (rawFrameMicros / 1000000.0).clamp(1 / 240, 1 / 20) * _timeScale;
    for (final scene in _activeScenes) {
      scene.stepBatch(
        dtSeconds,
        substeps: _substepsPerSample,
        config: _stepConfig,
      );
    }

    _smoothedFrameMicros = _smooth(_smoothedFrameMicros, rawFrameMicros);
    _sampleCount++;
    _painterTick.value++;

    if (_sampleCount % 8 == 0 && mounted) {
      setState(() {});
    }
  }

  double _smooth(double previous, double next) {
    if (previous == 0) {
      return next;
    }
    return (previous * 0.88) + (next * 0.12);
  }

  _BenchmarkVerdict _benchmarkVerdict() {
    final dartStepMicros =
        _scenes[GalaxyComputeBackend.dart]!.smoothedStepMicros;
    final ffiStepMicros =
        _scenes[GalaxyComputeBackend.cFfi]!.smoothedStepMicros;
    if (dartStepMicros <= 0 || ffiStepMicros <= 0) {
      return const _BenchmarkVerdict.warming();
    }

    final fasterKind =
        dartStepMicros <= ffiStepMicros
            ? GalaxyComputeBackend.dart
            : GalaxyComputeBackend.cFfi;
    final slowerMicros =
        fasterKind == GalaxyComputeBackend.dart
            ? ffiStepMicros
            : dartStepMicros;
    final fasterMicros =
        fasterKind == GalaxyComputeBackend.dart
            ? dartStepMicros
            : ffiStepMicros;
    final gain = ((slowerMicros - fasterMicros) / slowerMicros) * 100;

    return _BenchmarkVerdict.ready(winner: fasterKind, gainPercent: gain);
  }

  @override
  Widget build(BuildContext context) {
    final tickFps = 1000000 / _smoothedFrameMicros;
    final verdict = _benchmarkVerdict();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmos Benchmark'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              setState(_reseedAllScenes);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset field'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _BenchmarkLessonPanel(verdict: verdict),
          const SizedBox(height: 12),
          _OverviewPanel(
            viewMode: _viewMode,
            particleCount: _particleCount,
            visibleParticleCount: math.min(
              _particleCount,
              galaxyVisibleParticleLimit,
            ),
            substepsPerSample: _substepsPerSample,
            tickFps: tickFps,
            compareSummary: verdict.summary,
          ),
          const SizedBox(height: 12),
          _SceneGrid(
            scenes: _activeScenes.toList(growable: false),
            repaint: _painterTick,
            particleCount: _particleCount,
            visibleParticleCount: math.min(
              _particleCount,
              galaxyVisibleParticleLimit,
            ),
            substepsPerSample: _substepsPerSample,
          ),
          const SizedBox(height: 12),
          _ControlsPanel(
            viewMode: _viewMode,
            backendKind: _singleBackendKind,
            particleCount: _particleCount,
            substepsPerSample: _substepsPerSample,
            timeScale: _timeScale,
            swirl: _swirl,
            centerPull: _centerPull,
            onViewModeChanged: (mode) {
              if (mode == null || mode == _viewMode) {
                return;
              }
              setState(() {
                _viewMode = mode;
                _reseedAllScenes();
              });
            },
            onBackendChanged: (kind) {
              if (kind == null || kind == _singleBackendKind) {
                return;
              }
              setState(() {
                _singleBackendKind = kind;
                _reseedAllScenes();
              });
            },
            onParticleCountChanged: (value) {
              setState(() {
                _particleCount = value;
                _reseedAllScenes();
              });
            },
            onSubstepsChanged: (value) {
              setState(() {
                _substepsPerSample = value;
                _resetMetrics();
              });
            },
            onTimeScaleChanged: (value) {
              setState(() {
                _timeScale = value;
                _resetMetrics();
              });
            },
            onSwirlChanged: (value) {
              setState(() {
                _swirl = value;
                _reseedAllScenes();
              });
            },
            onCenterPullChanged: (value) {
              setState(() {
                _centerPull = value;
                _reseedAllScenes();
              });
            },
          ),
          const SizedBox(height: 12),
          const _BenchmarkNotesPanel(),
        ],
      ),
    );
  }
}

class _BenchmarkSceneState {
  _BenchmarkSceneState({required this.kind, required this.backend});

  final GalaxyComputeBackend kind;
  final GalaxySimulationBackend backend;
  double smoothedStepMicros = 0;
  double smoothedBatchMicros = 0;

  Float32List get particles => backend.particles;

  Duration stepBatch(
    double dtSeconds, {
    required int substeps,
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final duration = backend.stepBatch(
      dtSeconds,
      substeps: substeps,
      config: config,
    );
    final batchMicros = duration.inMicroseconds.toDouble();
    final stepMicros = batchMicros / substeps;
    smoothedBatchMicros = _smooth(smoothedBatchMicros, batchMicros);
    smoothedStepMicros = _smooth(smoothedStepMicros, stepMicros);
    return duration;
  }

  void reseed(
    int particleCount, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    backend.reseed(particleCount, config: config);
    resetMetrics();
  }

  void resetMetrics() {
    smoothedStepMicros = 0;
    smoothedBatchMicros = 0;
  }

  void dispose() {
    backend.dispose();
  }

  static double _smooth(double previous, double next) {
    if (previous == 0) {
      return next;
    }
    return (previous * 0.88) + (next * 0.12);
  }
}

class _BenchmarkVerdict {
  const _BenchmarkVerdict.warming()
    : isReady = false,
      winner = null,
      gainPercent = 0;

  const _BenchmarkVerdict.ready({
    required GalaxyComputeBackend this.winner,
    required this.gainPercent,
  }) : isReady = true;

  final bool isReady;
  final GalaxyComputeBackend? winner;
  final double gainPercent;

  String get summary {
    if (!isReady) {
      return 'Warming';
    }
    return '${_backendShortLabel(winner!)} wins';
  }

  String get title {
    if (!isReady) {
      return 'Benchmark is warming up';
    }
    if (winner == GalaxyComputeBackend.dart) {
      return 'Dart wins in this workload';
    }
    return 'C FFI wins in this workload';
  }

  String get body {
    if (!isReady) {
      return 'Wait for a few frames before reading the numbers.';
    }
    if (winner == GalaxyComputeBackend.dart) {
      return 'This is expected: the math is simple, Dart AOT is fast, and FFI still has boundary cost. FFI is not an automatic speed button.';
    }
    return 'Here the native batch is large enough to pay for the FFI boundary and still come out ahead.';
  }

  String get gainLabel {
    if (!isReady) {
      return 'collecting samples';
    }
    return '${gainPercent.toStringAsFixed(1)}% faster';
  }
}

class _BenchmarkLessonPanel extends StatelessWidget {
  const _BenchmarkLessonPanel({required this.verdict});

  final _BenchmarkVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Benchmark lesson',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(
                label: Text(verdict.gainLabel),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(verdict.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(verdict.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LessonChip(
                icon: Icons.check_circle,
                text: 'Good for native SDKs',
              ),
              _LessonChip(icon: Icons.call_merge, text: 'Batch native work'),
              _LessonChip(icon: Icons.warning_amber, text: 'Avoid tiny calls'),
              _LessonChip(
                icon: Icons.rocket_launch,
                text: 'Measure release builds',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.viewMode,
    required this.particleCount,
    required this.visibleParticleCount,
    required this.substepsPerSample,
    required this.tickFps,
    required this.compareSummary,
  });

  final GalaxyBenchmarkViewMode viewMode;
  final int particleCount;
  final int visibleParticleCount;
  final int substepsPerSample;
  final double tickFps;
  final String compareSummary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _MetricCard(
          label: 'View mode',
          value: switch (viewMode) {
            GalaxyBenchmarkViewMode.compare => 'Compare mode',
            GalaxyBenchmarkViewMode.single => 'Single backend',
          },
        ),
        _MetricCard(
          label: 'Tick rate',
          value: '${tickFps.toStringAsFixed(1)} fps',
        ),
        _MetricCard(
          label: 'Compute load',
          value: '${_formatCompactCount(particleCount)} particles',
        ),
        _MetricCard(label: 'Batch size', value: '$substepsPerSample substeps'),
        _MetricCard(
          label: 'Drawn particles',
          value: '${_formatCompactCount(visibleParticleCount)} visible',
        ),
        _MetricCard(label: 'Compare summary', value: compareSummary),
      ],
    );
  }
}

class _SceneGrid extends StatelessWidget {
  const _SceneGrid({
    required this.scenes,
    required this.repaint,
    required this.particleCount,
    required this.visibleParticleCount,
    required this.substepsPerSample,
  });

  final List<_BenchmarkSceneState> scenes;
  final Listenable repaint;
  final int particleCount;
  final int visibleParticleCount;
  final int substepsPerSample;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final narrow = constraints.maxWidth < 900;
        final cardWidth =
            narrow || scenes.length == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              scenes
                  .map(
                    (scene) => SizedBox(
                      width: cardWidth,
                      child: _SceneCard(
                        scene: scene,
                        repaint: repaint,
                        particleCount: particleCount,
                        visibleParticleCount: visibleParticleCount,
                        substepsPerSample: substepsPerSample,
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.repaint,
    required this.particleCount,
    required this.visibleParticleCount,
    required this.substepsPerSample,
  });

  final _BenchmarkSceneState scene;
  final Listenable repaint;
  final int particleCount;
  final int visibleParticleCount;
  final int substepsPerSample;

  @override
  Widget build(BuildContext context) {
    final particlesPerSecond =
        scene.smoothedBatchMicros == 0
            ? 0
            : (particleCount * substepsPerSample * 1000000) /
                scene.smoothedBatchMicros;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _backendLabel(scene.kind),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(_sceneTag(scene.kind)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _SceneMetricChip(
                  label: 'Avg step',
                  value:
                      '${(scene.smoothedStepMicros / 1000).toStringAsFixed(3)} ms',
                ),
                _SceneMetricChip(
                  label: 'Batch',
                  value:
                      '${(scene.smoothedBatchMicros / 1000).toStringAsFixed(2)} ms',
                ),
                _SceneMetricChip(
                  label: 'Updates / sec',
                  value: _formatCompactCount(particlesPerSecond.round()),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF04070D)),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GalaxyPainter(
                        particles: scene.particles,
                        visibleParticleCount: visibleParticleCount,
                        repaint: repaint,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _HeroBadge(
                      label:
                          'Renderer: Flutter canvas | Compute: ${_backendLabel(scene.kind)}',
                    ),
                  ),
                  const Positioned(
                    right: 16,
                    bottom: 16,
                    child: _HeroBadge(
                      label: 'Calm starfield, same dt, same seed',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.viewMode,
    required this.backendKind,
    required this.particleCount,
    required this.substepsPerSample,
    required this.timeScale,
    required this.swirl,
    required this.centerPull,
    required this.onViewModeChanged,
    required this.onBackendChanged,
    required this.onParticleCountChanged,
    required this.onSubstepsChanged,
    required this.onTimeScaleChanged,
    required this.onSwirlChanged,
    required this.onCenterPullChanged,
  });

  final GalaxyBenchmarkViewMode viewMode;
  final GalaxyComputeBackend backendKind;
  final int particleCount;
  final int substepsPerSample;
  final double timeScale;
  final double swirl;
  final double centerPull;
  final ValueChanged<GalaxyBenchmarkViewMode?> onViewModeChanged;
  final ValueChanged<GalaxyComputeBackend?> onBackendChanged;
  final ValueChanged<int> onParticleCountChanged;
  final ValueChanged<int> onSubstepsChanged;
  final ValueChanged<double> onTimeScaleChanged;
  final ValueChanged<double> onSwirlChanged;
  final ValueChanged<double> onCenterPullChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Compute controls',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<GalaxyBenchmarkViewMode>(
            segments: const <ButtonSegment<GalaxyBenchmarkViewMode>>[
              ButtonSegment(
                value: GalaxyBenchmarkViewMode.compare,
                label: Text('Compare'),
                icon: Icon(Icons.view_week),
              ),
              ButtonSegment(
                value: GalaxyBenchmarkViewMode.single,
                label: Text('Single'),
                icon: Icon(Icons.filter_1),
              ),
            ],
            selected: <GalaxyBenchmarkViewMode>{viewMode},
            onSelectionChanged:
                (value) =>
                    onViewModeChanged(value.isEmpty ? null : value.first),
          ),
          const SizedBox(height: 12),
          if (viewMode == GalaxyBenchmarkViewMode.single)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<GalaxyComputeBackend>(
                segments: const <ButtonSegment<GalaxyComputeBackend>>[
                  ButtonSegment(
                    value: GalaxyComputeBackend.dart,
                    label: Text('Pure Dart'),
                    icon: Icon(Icons.code),
                  ),
                  ButtonSegment(
                    value: GalaxyComputeBackend.cFfi,
                    label: Text('C via FFI'),
                    icon: Icon(Icons.memory),
                  ),
                ],
                selected: <GalaxyComputeBackend>{backendKind},
                onSelectionChanged:
                    (value) =>
                        onBackendChanged(value.isEmpty ? null : value.first),
              ),
            ),
          Text(
            'Compute particles',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                galaxyComputeParticlePresets
                    .map(
                      (preset) => ChoiceChip(
                        label: Text('${_formatCompactCount(preset)} particles'),
                        selected: particleCount == preset,
                        onSelected: (_) => onParticleCountChanged(preset),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Text('Work per frame', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                galaxySubstepPresets
                    .map(
                      (preset) => ChoiceChip(
                        label: Text('$preset substeps'),
                        selected: substepsPerSample == preset,
                        onSelected: (_) => onSubstepsChanged(preset),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Time scale',
            value: timeScale,
            min: 0.4,
            max: 1.2,
            divisions: 8,
            valueLabel: timeScale.toStringAsFixed(2),
            onChanged: onTimeScaleChanged,
          ),
          _SliderRow(
            label: 'Micro turbulence',
            value: swirl,
            min: 0.04,
            max: 0.32,
            divisions: 14,
            valueLabel: swirl.toStringAsFixed(2),
            onChanged: onSwirlChanged,
          ),
          _SliderRow(
            label: 'Star drift',
            value: centerPull,
            min: 0.02,
            max: 0.16,
            divisions: 14,
            valueLabel: centerPull.toStringAsFixed(2),
            onChanged: onCenterPullChanged,
          ),
        ],
      ),
    );
  }
}

class _BenchmarkNotesPanel extends StatelessWidget {
  const _BenchmarkNotesPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Benchmark notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _NoteRow(
            icon: Icons.balance,
            text:
                'Compare mode reseeds both backends together so they start from the same calm starfield.',
          ),
          const _NoteRow(
            icon: Icons.call_merge,
            text:
                'The FFI path does all selected substeps inside one native call per frame.',
          ),
          const _NoteRow(
            icon: Icons.storage,
            text:
                'Compute can use a larger native buffer than the number of particles drawn on screen.',
          ),
          const _NoteRow(
            icon: Icons.warning_amber,
            text:
                'If Dart wins here, the correct lesson is: keep simple logic in Dart.',
          ),
          const _NoteRow(
            icon: Icons.inventory_2,
            text:
                'Use FFI when native code gives you a capability: SDK, audited library, hardware API, or existing engine.',
          ),
        ],
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({
    required this.particles,
    required this.visibleParticleCount,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Float32List particles;
  final int visibleParticleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final scale = math.min(size.width, size.height) * 0.46;

    final backgroundPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF02040A),
              Color(0xFF06101A),
              Color(0xFF10121F),
            ],
          ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final nebulaPaint =
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFF64D2FF).withValues(alpha: 0.16),
              const Color(0xFFB6F08A).withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.34, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.32, size.height * 0.42),
              radius: scale * 0.9,
            ),
          );
    canvas.drawRect(rect, nebulaPaint);

    final dustPaint =
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFD37A).withValues(alpha: 0.09),
              const Color(0xFF7C8CFF).withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.38, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.62),
              radius: scale * 0.82,
            ),
          );
    canvas.drawRect(rect, dustPaint);

    final visibleValueCount = math.min(
      particles.length,
      visibleParticleCount * galaxyParticleStride,
    );

    for (
      var offset = 0;
      offset < visibleValueCount;
      offset += galaxyParticleStride
    ) {
      final x = particles[offset].toDouble();
      final y = particles[offset + 1].toDouble();
      final vx = particles[offset + 2].toDouble();
      final vy = particles[offset + 3].toDouble();
      final position = Offset(center.dx + x * scale, center.dy + y * scale);
      final particleIndex = offset ~/ galaxyParticleStride;
      final depth = _fractional((particleIndex + 1) * 0.38196601125);
      final warmth = _fractional((particleIndex + 1) * 0.2360679775);
      final speed = math.min(math.sqrt((vx * vx) + (vy * vy)) * 20, 1.0);
      final hue = warmth > 0.88 ? 42.0 : lerpDouble(198, 228, depth)!;
      final saturation = warmth > 0.88 ? 0.74 : lerpDouble(0.26, 0.56, depth)!;
      final lightness = lerpDouble(0.54, 0.82, depth)!;
      final glowColor =
          HSLColor.fromAHSL(
            0.18 + (depth * 0.28),
            hue,
            saturation,
            (lightness + speed * 0.08).clamp(0.0, 1.0),
          ).toColor();
      final radius = lerpDouble(0.45, 1.18, depth)! + speed * 0.18;

      canvas.drawCircle(
        position,
        radius * 2.1,
        Paint()..color = glowColor.withValues(alpha: 0.045),
      );
      canvas.drawCircle(position, radius, Paint()..color = glowColor);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return !identical(oldDelegate.particles, particles) ||
        oldDelegate.visibleParticleCount != visibleParticleCount;
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return SizedBox(
      width: 208,
      child: _Panel(
        child: SizedBox(
          height: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: valueStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneMetricChip extends StatelessWidget {
  const _SceneMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Chip(
        label: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101827).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF7FDBFF).withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE6F2FF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[Expanded(child: Text(label)), Text(valueLabel)]),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _backendLabel(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'Pure Dart',
    GalaxyComputeBackend.cFfi => 'C via FFI',
  };
}

String _backendShortLabel(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'Dart',
    GalaxyComputeBackend.cFfi => 'C FFI',
  };
}

String _sceneTag(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'No FFI',
    GalaxyComputeBackend.cFfi => 'Native batch step',
  };
}

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final thousands = value / 1000;
    return thousands >= 10
        ? '${thousands.toStringAsFixed(0)}k'
        : '${thousands.toStringAsFixed(1)}k';
  }
  return value.toString();
}

double _fractional(double value) => value - value.floorToDouble();
