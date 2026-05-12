part of '../galaxy_benchmark_page.dart';

/// Fifth app tab: animated galaxy with per-backend timing and optional shader visuals.
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

    return AdaptivePageScaffold(
      title: 'Cosmos Benchmark',
      actions: <Widget>[
        AdaptiveAppBarAction(
          onPressed: () {
            setState(_reseedAllScenes);
          },
          icon: Icons.refresh,
          label: 'Reset field',
        ),
        const SizedBox(width: 12),
      ],
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
