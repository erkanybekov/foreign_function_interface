import 'dart:math' as math;
import 'dart:ui' show FontFeature, FragmentProgram, lerpDouble;

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'galaxy_simulation.dart';

const List<int> galaxyComputeParticlePresets = <int>[8192, 32768, 65536];
const List<int> galaxySubstepPresets = <int>[1, 4, 8];
const int galaxyVisibleParticleLimit = 3072;

enum GalaxyBenchmarkViewMode { compare, single }

enum GalaxyVisualEffect {
  nebula,
  starWarp,
  gravitationalLens,
  aurora,
  riskHeatmap,
  deviceFingerprint,
}

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
  bool? _hasRustBackend;

  GalaxyBenchmarkViewMode _viewMode = GalaxyBenchmarkViewMode.compare;
  GalaxyComputeBackend _singleBackendKind = GalaxyComputeBackend.dart;
  GalaxyVisualEffect _visualEffect = GalaxyVisualEffect.nebula;
  int _particleCount = 32768;
  int _substepsPerSample = 4;
  double _timeScale = 0.8;
  double _swirl = 0.18;
  double _centerPull = 0.08;
  double _smoothedFrameMicros = 16667;
  int _sampleCount = 0;
  Duration? _lastElapsed;

  FragmentProgram? _nebulaProgram;
  FragmentProgram? _auroraProgram;
  bool _useFragmentShaders = true;

  @override
  void initState() {
    super.initState();
    _painterTick = ValueNotifier<int>(0);
    _scenes = <GalaxyComputeBackend, _BenchmarkSceneState>{
      for (final kind in _availableBackendKinds)
        kind: _createScene(kind, particleCount: _particleCount),
    };
    _ticker = createTicker(_handleTick)..start();
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      final results = await Future.wait(<Future<FragmentProgram>>[
        FragmentProgram.fromAsset('shaders/nebula.frag'),
        FragmentProgram.fromAsset('shaders/aurora.frag'),
      ]);
      if (mounted) {
        setState(() {
          _nebulaProgram = results[0];
          _auroraProgram = results[1];
        });
      }
    } catch (e) {
      // Shaders unavailable — fallback to software Canvas rendering.
      debugPrint('Galaxy shaders could not be loaded: $e');
    }
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
        _scenes[_singleBackendKind] ?? _scenes[GalaxyComputeBackend.dart]!,
      ],
    };
  }

  List<GalaxyComputeBackend> get _availableBackendKinds {
    return <GalaxyComputeBackend>[
      GalaxyComputeBackend.dart,
      GalaxyComputeBackend.cFfi,
      if (_rustBackendAvailable) GalaxyComputeBackend.rustFfi,
    ];
  }

  bool get _rustBackendAvailable {
    if (widget.backendBuilder != null) {
      return true;
    }
    return _hasRustBackend ??= _resolvedCore.hasRustBackend;
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
        GalaxyComputeBackend.rustFfi => RustGalaxySimulationBackend(
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
    final samples =
        _scenes.values
            .where((scene) => scene.smoothedStepMicros > 0)
            .map(
              (scene) => (
                kind: scene.kind,
                stepMicros: scene.smoothedStepMicros,
              ),
            )
            .toList()
          ..sort((a, b) => a.stepMicros.compareTo(b.stepMicros));

    if (samples.length < _scenes.length || samples.length < 2) {
      return const _BenchmarkVerdict.warming();
    }

    final winner = samples.first;
    final runnerUp = samples[1];
    final gain =
        ((runnerUp.stepMicros - winner.stepMicros) / runnerUp.stepMicros) * 100;

    return _BenchmarkVerdict.ready(winner: winner.kind, gainPercent: gain);
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
          _VisualEffectPanel(
            selected: _visualEffect,
            onChanged: (effect) {
              setState(() {
                _visualEffect = effect;
              });
            },
          ),
          const SizedBox(height: 12),
          _FragmentShaderPanel(
            useFragmentShaders: _useFragmentShaders,
            shadersLoaded: _nebulaProgram != null && _auroraProgram != null,
            onChanged: (value) {
              setState(() {
                _useFragmentShaders = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _OverviewPanel(
            viewMode: _viewMode,
            visualEffect: _visualEffect,
            particleCount: _particleCount,
            visibleParticleCount: math.min(
              _particleCount,
              galaxyVisibleParticleLimit,
            ),
            availableBackends: _availableBackendKinds,
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
            visualEffect: _visualEffect,
            useFragmentShaders: _useFragmentShaders,
            nebulaProgram: _nebulaProgram,
            auroraProgram: _auroraProgram,
          ),
          const SizedBox(height: 12),
          _ControlsPanel(
            viewMode: _viewMode,
            backendKind: _singleBackendKind,
            availableBackends: _availableBackendKinds,
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
    return '${_backendShortLabel(winner!)} wins in this workload';
  }

  String get body {
    if (!isReady) {
      return 'Wait for a few frames before reading the numbers.';
    }
    if (winner == GalaxyComputeBackend.dart) {
      return 'This is expected: the math is simple, Dart AOT is fast, and FFI still has boundary cost. FFI is not an automatic speed button.';
    }
    return 'Here the native batch is large enough to pay for the FFI boundary and still come out ahead. Compare C and Rust by keeping the particle count and substeps fixed.';
  }

  String get gainLabel {
    if (!isReady) {
      return 'collecting samples';
    }
    return '${gainPercent.toStringAsFixed(1)}% over next';
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

class _VisualEffectPanel extends StatelessWidget {
  const _VisualEffectPanel({required this.selected, required this.onChanged});

  final GalaxyVisualEffect selected;
  final ValueChanged<GalaxyVisualEffect> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedInfo = selected.info;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                selectedInfo.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Galaxy visual selector',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedInfo.body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                GalaxyVisualEffect.values
                    .map(
                      (effect) => _VisualEffectOption(
                        effect: effect,
                        selected: selected == effect,
                        onTap: () => onChanged(effect),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _FragmentShaderPanel extends StatelessWidget {
  const _FragmentShaderPanel({
    required this.useFragmentShaders,
    required this.shadersLoaded,
    required this.onChanged,
  });

  final bool useFragmentShaders;
  final bool shadersLoaded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        shadersLoaded
            ? 'On: FragmentProgram (GLSL). Off: Canvas gradients and paths (original painter).'
            : 'GLSL did not load — Nebula and Aurora always use the Canvas painter.';

    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Nebula / Aurora shading',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                useFragmentShaders ? 'GLSL' : 'Canvas',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Switch.adaptive(value: useFragmentShaders, onChanged: onChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisualEffectOption extends StatelessWidget {
  const _VisualEffectOption({
    required this.effect,
    required this.selected,
    required this.onTap,
  });

  final GalaxyVisualEffect effect;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = effect.info;
    final background =
        selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : colorScheme.surface;
    final borderColor =
        selected
            ? colorScheme.primary.withValues(alpha: 0.26)
            : colorScheme.outlineVariant;
    final iconBackground =
        selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.78);
    final foreground =
        selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        width: 248,
        height: 52,
        child: Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  SizedBox.square(
                    dimension: 32,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(info.icon, size: 19, color: foreground),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.viewMode,
    required this.visualEffect,
    required this.particleCount,
    required this.visibleParticleCount,
    required this.availableBackends,
    required this.substepsPerSample,
    required this.tickFps,
    required this.compareSummary,
  });

  final GalaxyBenchmarkViewMode viewMode;
  final GalaxyVisualEffect visualEffect;
  final int particleCount;
  final int visibleParticleCount;
  final List<GalaxyComputeBackend> availableBackends;
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
        _MetricCard(
          label: 'Backends',
          value: availableBackends.map(_backendShortLabel).join(' / '),
        ),
        _MetricCard(label: 'Visual layer', value: visualEffect.info.shortLabel),
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
    required this.visualEffect,
    required this.useFragmentShaders,
    this.nebulaProgram,
    this.auroraProgram,
  });

  final List<_BenchmarkSceneState> scenes;
  final ValueListenable<int> repaint;
  final int particleCount;
  final int visibleParticleCount;
  final int substepsPerSample;
  final GalaxyVisualEffect visualEffect;
  final bool useFragmentShaders;
  final FragmentProgram? nebulaProgram;
  final FragmentProgram? auroraProgram;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final narrow = constraints.maxWidth < 900;
        final columnCount =
            narrow || scenes.length == 1
                ? 1
                : constraints.maxWidth >= 1180
                ? math.min(3, scenes.length)
                : 2;
        final cardWidth =
            (constraints.maxWidth - (12 * (columnCount - 1))) / columnCount;

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
                        visualEffect: visualEffect,
                        useFragmentShaders: useFragmentShaders,
                        nebulaProgram: nebulaProgram,
                        auroraProgram: auroraProgram,
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
    required this.visualEffect,
    required this.useFragmentShaders,
    this.nebulaProgram,
    this.auroraProgram,
  });

  final _BenchmarkSceneState scene;
  final ValueListenable<int> repaint;
  final int particleCount;
  final int visibleParticleCount;
  final int substepsPerSample;
  final GalaxyVisualEffect visualEffect;
  final bool useFragmentShaders;
  final FragmentProgram? nebulaProgram;
  final FragmentProgram? auroraProgram;

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
                        visualEffect: visualEffect,
                        ticker: repaint,
                        useFragmentShaders: useFragmentShaders,
                        nebulaProgram: nebulaProgram,
                        auroraProgram: auroraProgram,
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
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _HeroBadge(
                      label:
                          '${visualEffect.info.shortLabel} | orbiting galaxy',
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
    required this.availableBackends,
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
  final List<GalaxyComputeBackend> availableBackends;
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
                segments:
                    availableBackends
                        .map(
                          (backend) => ButtonSegment<GalaxyComputeBackend>(
                            value: backend,
                            label: Text(_backendShortLabel(backend)),
                            icon: Icon(_backendIcon(backend)),
                          ),
                        )
                        .toList(),
                selected: <GalaxyComputeBackend>{
                  availableBackends.contains(backendKind)
                      ? backendKind
                      : availableBackends.first,
                },
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
            label: 'Orbit force',
            value: swirl,
            min: 0.04,
            max: 0.32,
            divisions: 14,
            valueLabel: swirl.toStringAsFixed(2),
            onChanged: onSwirlChanged,
          ),
          _SliderRow(
            label: 'Galaxy spread',
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
                'Compare mode reseeds all backends together so they start from the same galaxy field.',
          ),
          const _NoteRow(
            icon: Icons.palette,
            text:
                'Visual selector changes only the canvas layer; the Dart, C, and Rust compute paths stay comparable.',
          ),
          const _NoteRow(
            icon: Icons.call_merge,
            text:
                'Each FFI path does all selected substeps inside one native call per frame.',
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
    required this.visualEffect,
    required ValueListenable<int> ticker,
    required this.useFragmentShaders,
    this.nebulaProgram,
    this.auroraProgram,
  }) : _ticker = ticker,
       super(repaint: ticker);

  final Float32List particles;
  final int visibleParticleCount;
  final GalaxyVisualEffect visualEffect;
  final bool useFragmentShaders;
  final FragmentProgram? nebulaProgram;
  final FragmentProgram? auroraProgram;
  final ValueListenable<int> _ticker;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final scale = math.min(size.width, size.height) * 0.46;
    final time = _ticker.value / 60.0;

    _drawBaseSpace(canvas, rect);
    switch (visualEffect) {
      case GalaxyVisualEffect.nebula:
        _drawNebula(canvas, size, scale, time);
      case GalaxyVisualEffect.starWarp:
        _drawStarWarp(canvas, center, scale, time);
      case GalaxyVisualEffect.gravitationalLens:
        _drawGravitationalLens(canvas, center, scale, time);
      case GalaxyVisualEffect.aurora:
        _drawAurora(canvas, size, time);
      case GalaxyVisualEffect.riskHeatmap:
        _drawRiskHeatmap(canvas, center, scale, time);
      case GalaxyVisualEffect.deviceFingerprint:
        _drawDeviceFingerprintField(canvas, center, scale, time);
    }

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
      final particleIndex = offset ~/ galaxyParticleStride;
      final projected = _projectGalaxyParticle(
        x: x,
        y: y,
        particleIndex: particleIndex,
        center: center,
        scale: scale,
        time: time,
      );
      final depth = _fractional((particleIndex + 1) * 0.38196601125);
      final warmth = _fractional((particleIndex + 1) * 0.2360679775);
      final speed = math.min(math.sqrt((vx * vx) + (vy * vy)) * 20, 1.0);
      final glowColor = _particleColor(
        depth: depth,
        warmth: warmth,
        speed: speed,
        particleIndex: particleIndex,
      );
      final radius = lerpDouble(0.45, 1.18, depth)! + speed * 0.18;

      if (visualEffect == GalaxyVisualEffect.starWarp) {
        final radial = projected - center;
        final distance = radial.distance;
        if (distance > 0) {
          final direction = radial / distance;
          canvas.drawLine(
            projected - direction * (6 + speed * 18),
            projected + direction * (2 + speed * 5),
            Paint()
              ..color = glowColor.withValues(alpha: 0.16)
              ..strokeWidth = 1.2 + speed
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      canvas.drawCircle(
        projected,
        radius * 2.1,
        Paint()..color = glowColor.withValues(alpha: 0.045),
      );
      canvas.drawCircle(projected, radius, Paint()..color = glowColor);
    }
  }

  void _drawBaseSpace(Canvas canvas, Rect rect) {
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
  }

  void _drawNebula(Canvas canvas, Size size, double scale, double time) {
    final program = useFragmentShaders ? nebulaProgram : null;
    if (program != null) {
      final shader =
          program.fragmentShader()
            ..setFloat(0, size.width) // uSize.x
            ..setFloat(1, size.height) // uSize.y
            ..setFloat(2, time) // uTime
            ..setFloat(3, scale); // uScale
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
      return;
    }

    // Software fallback (original gradient implementation)
    final firstCenter = Offset(
      size.width * (0.30 + math.sin(time * 0.18) * 0.04),
      size.height * (0.42 + math.cos(time * 0.14) * 0.04),
    );
    final secondCenter = Offset(
      size.width * (0.72 + math.cos(time * 0.11) * 0.03),
      size.height * (0.62 + math.sin(time * 0.16) * 0.03),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF64D2FF).withValues(alpha: 0.18),
            const Color(0xFFB6F08A).withValues(alpha: 0.07),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.34, 1.0],
        ).createShader(Rect.fromCircle(center: firstCenter, radius: scale)),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFD37A).withValues(alpha: 0.10),
            const Color(0xFF7C8CFF).withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.38, 1.0],
        ).createShader(Rect.fromCircle(center: secondCenter, radius: scale)),
    );
  }

  void _drawStarWarp(Canvas canvas, Offset center, double scale, double time) {
    for (var index = 0; index < 96; index++) {
      final seed = _fractional((index + 1) * 0.75487766625);
      final angle = (seed * math.pi * 2) + time * 0.08;
      final distance = scale * (0.16 + _fractional(seed * 7.13 + time * 0.18));
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = center + direction * (distance - 10);
      final end = center + direction * (distance + 18 + seed * 34);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(
            0xFFBDEBFF,
          ).withValues(alpha: 0.06 + seed * 0.10)
          ..strokeWidth = 0.8 + seed * 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawGravitationalLens(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    canvas.drawCircle(
      center,
      scale * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.13),
            const Color(0xFF7FDBFF).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: scale * 0.42)),
    );
    for (var ring = 0; ring < 3; ring++) {
      canvas.drawCircle(
        center,
        scale * (0.18 + ring * 0.12 + math.sin(time * 0.5 + ring) * 0.008),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFDDF7FF).withValues(alpha: 0.10),
      );
    }
  }

  void _drawAurora(Canvas canvas, Size size, double time) {
    final program = useFragmentShaders ? auroraProgram : null;
    if (program != null) {
      final shader =
          program.fragmentShader()
            ..setFloat(0, size.width) // uSize.x
            ..setFloat(1, size.height) // uSize.y
            ..setFloat(2, time); // uTime
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
      return;
    }

    // Software fallback (original polyline implementation)
    final colors = <Color>[
      const Color(0xFF6EF2B8),
      const Color(0xFF69D3FF),
      const Color(0xFFB692FF),
    ];
    for (var ribbon = 0; ribbon < colors.length; ribbon++) {
      final path = Path();
      for (var step = 0; step <= 24; step++) {
        final x = size.width * (step / 24);
        final y =
            size.height * (0.28 + ribbon * 0.13) +
            math.sin(step * 0.72 + time * (0.45 + ribbon * 0.12)) * 28 +
            math.cos(step * 0.31 + time * 0.30) * 16;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20 - ribbon * 3
          ..strokeCap = StrokeCap.round
          ..color = colors[ribbon].withValues(alpha: 0.11),
      );
    }
  }

  void _drawRiskHeatmap(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawCircle(
        center,
        scale * ring * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9EE493).withValues(alpha: 0.10),
      );
    }
    final sweep = math.pi * 0.58;
    final start = -math.pi / 2 + time * 0.22;
    final zones = <({double radius, Color color, double offset})>[
      (radius: 0.34, color: const Color(0xFF9EE493), offset: 0),
      (radius: 0.58, color: const Color(0xFFFFD166), offset: 0.52),
      (radius: 0.82, color: const Color(0xFFFF5C7A), offset: 1.04),
    ];
    for (final zone in zones) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: scale * zone.radius),
        start + zone.offset,
        sweep,
        true,
        Paint()..color = zone.color.withValues(alpha: 0.10),
      );
    }
    canvas.drawLine(
      center,
      center + Offset(math.cos(start), math.sin(start)) * scale * 0.88,
      Paint()
        ..color = const Color(0xFFB6F08A).withValues(alpha: 0.24)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDeviceFingerprintField(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    final arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7FDBFF).withValues(alpha: 0.12);
    for (var ring = 0; ring < 7; ring++) {
      final width = scale * (0.38 + ring * 0.13);
      final height = scale * (0.24 + ring * 0.09);
      final rect = Rect.fromCenter(
        center: center + Offset(math.sin(time * 0.2 + ring) * 5, 0),
        width: width,
        height: height,
      );
      canvas.drawArc(
        rect,
        -math.pi * 0.86 + ring * 0.13,
        math.pi * 1.45,
        false,
        arcPaint,
      );
    }

    for (var index = 0; index < 34; index++) {
      final seed = _fractional((index + 1) * 0.61803398875);
      final angle = seed * math.pi * 2;
      final radius = scale * (0.18 + _fractional(seed * 5.77) * 0.72);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        1.3,
        Paint()..color = const Color(0xFFBDEBFF).withValues(alpha: 0.30),
      );
    }
  }

  Offset _projectGalaxyParticle({
    required double x,
    required double y,
    required int particleIndex,
    required Offset center,
    required double scale,
    required double time,
  }) {
    final rawRadius = math.sqrt((x * x) + (y * y));
    final normalizedRadius = (rawRadius / 1.18).clamp(0.0, 1.0).toDouble();
    var radius = (0.08 + normalizedRadius * 0.96) * scale;
    var angle = math.atan2(y, x);

    angle += time * 0.22;
    angle += (1.0 - normalizedRadius) * 2.85;
    angle += (particleIndex % 3) * 0.11;
    angle += math.sin(particleIndex * 0.071) * 0.05;

    if (visualEffect == GalaxyVisualEffect.gravitationalLens) {
      final lens = ((0.42 - normalizedRadius) / 0.42).clamp(0.0, 1.0);
      angle += lens * lens * math.sin(time * 0.7) * 0.16;
      radius *= 1.0 + lens * 0.10;
    }

    if (visualEffect == GalaxyVisualEffect.starWarp) {
      radius *= 1.0 + math.sin(time * 2.0 + particleIndex) * 0.015;
    }

    final projected = Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius * 0.68,
    );
    return center + projected;
  }

  Color _particleColor({
    required double depth,
    required double warmth,
    required double speed,
    required int particleIndex,
  }) {
    if (visualEffect == GalaxyVisualEffect.riskHeatmap) {
      final risk = _fractional((particleIndex + 1) * 0.17320508075);
      final color =
          risk > 0.72
              ? const Color(0xFFFF5C7A)
              : risk > 0.44
              ? const Color(0xFFFFD166)
              : const Color(0xFF9EE493);
      return color.withValues(alpha: 0.28 + depth * 0.30);
    }

    if (visualEffect == GalaxyVisualEffect.deviceFingerprint) {
      return HSLColor.fromAHSL(
        0.24 + depth * 0.34,
        lerpDouble(178, 205, depth)!,
        0.64,
        (0.58 + speed * 0.10).clamp(0.0, 1.0),
      ).toColor();
    }

    if (visualEffect == GalaxyVisualEffect.aurora) {
      return HSLColor.fromAHSL(
        0.20 + depth * 0.30,
        lerpDouble(148, 286, _fractional(depth + warmth))!,
        0.62,
        (0.58 + speed * 0.10).clamp(0.0, 1.0),
      ).toColor();
    }

    final hue = warmth > 0.88 ? 42.0 : lerpDouble(198, 228, depth)!;
    final saturation = warmth > 0.88 ? 0.74 : lerpDouble(0.26, 0.56, depth)!;
    final lightness = lerpDouble(0.54, 0.82, depth)!;
    return HSLColor.fromAHSL(
      0.18 + (depth * 0.28),
      hue,
      saturation,
      (lightness + speed * 0.08).clamp(0.0, 1.0),
    ).toColor();
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return !identical(oldDelegate.particles, particles) ||
        oldDelegate.visibleParticleCount != visibleParticleCount ||
        oldDelegate.visualEffect != visualEffect ||
        oldDelegate.useFragmentShaders != useFragmentShaders ||
        oldDelegate.nebulaProgram != nebulaProgram ||
        oldDelegate.auroraProgram != auroraProgram;
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
    GalaxyComputeBackend.rustFfi => 'Rust via FFI',
  };
}

String _backendShortLabel(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'Dart',
    GalaxyComputeBackend.cFfi => 'C FFI',
    GalaxyComputeBackend.rustFfi => 'Rust FFI',
  };
}

String _sceneTag(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'No FFI',
    GalaxyComputeBackend.cFfi => 'Native batch step',
    GalaxyComputeBackend.rustFfi => 'Rust crate step',
  };
}

IconData _backendIcon(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => Icons.code,
    GalaxyComputeBackend.cFfi => Icons.memory,
    GalaxyComputeBackend.rustFfi => Icons.hub,
  };
}

class _GalaxyVisualEffectInfo {
  const _GalaxyVisualEffectInfo({
    required this.label,
    required this.shortLabel,
    required this.body,
    required this.icon,
  });

  final String label;
  final String shortLabel;
  final String body;
  final IconData icon;
}

extension _GalaxyVisualEffectInfoExtension on GalaxyVisualEffect {
  _GalaxyVisualEffectInfo get info {
    return switch (this) {
      GalaxyVisualEffect.nebula => const _GalaxyVisualEffectInfo(
        label: 'Nebula Shader',
        shortLabel: 'Nebula',
        body: 'Soft living cosmic cloud behind the orbiting galaxy.',
        icon: Icons.cloud,
      ),
      GalaxyVisualEffect.starWarp => const _GalaxyVisualEffectInfo(
        label: 'Star Warp Shader',
        shortLabel: 'Star Warp',
        body: 'Hyperspace streaks around the same particle compute.',
        icon: Icons.rocket_launch,
      ),
      GalaxyVisualEffect.gravitationalLens => const _GalaxyVisualEffectInfo(
        label: 'Gravitational Lens',
        shortLabel: 'Lens',
        body:
            'The center bends the scene slightly without turning into a vortex.',
        icon: Icons.blur_circular,
      ),
      GalaxyVisualEffect.aurora => const _GalaxyVisualEffectInfo(
        label: 'Aurora / Plasma Ribbons',
        shortLabel: 'Aurora',
        body: 'Slow color ribbons for a guide or onboarding mood.',
        icon: Icons.waves,
      ),
      GalaxyVisualEffect.riskHeatmap => const _GalaxyVisualEffectInfo(
        label: 'Risk Heatmap Shader',
        shortLabel: 'Risk Heatmap',
        body: 'Fraud-style radar zones: low, medium, and high risk.',
        icon: Icons.radar,
      ),
      GalaxyVisualEffect.deviceFingerprint => const _GalaxyVisualEffectInfo(
        label: 'Device Fingerprint Field',
        shortLabel: 'Fingerprint',
        body: 'Signals, arcs, and device graph feel for AntiFraud demos.',
        icon: Icons.fingerprint,
      ),
    };
  }
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
