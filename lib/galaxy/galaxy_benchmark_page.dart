import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show lerpDouble;

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'galaxy_simulation.dart';

const List<int> galaxyParticlePresets = <int>[768, 1536, 3072];

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
  int _particleCount = 1536;
  double _timeScale = 1.0;
  double _swirl = 1.35;
  double _centerPull = 1.6;
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
    damping: 0.995,
    escapeRadius: 1.25,
    respawnRadius: 0.95,
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
      scene.step(dtSeconds, config: _stepConfig);
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

  String _compareSummary() {
    final dartStepMicros =
        _scenes[GalaxyComputeBackend.dart]!.smoothedStepMicros;
    final ffiStepMicros =
        _scenes[GalaxyComputeBackend.cFfi]!.smoothedStepMicros;
    if (dartStepMicros <= 0 || ffiStepMicros <= 0) {
      return 'warming up';
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

    return '${_backendLabel(fasterKind)} faster by ${gain.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final tickFps = 1000000 / _smoothedFrameMicros;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galaxy Benchmark'),
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
          _OverviewPanel(
            viewMode: _viewMode,
            particleCount: _particleCount,
            tickFps: tickFps,
            compareSummary: _compareSummary(),
          ),
          const SizedBox(height: 12),
          _SceneGrid(
            scenes: _activeScenes.toList(growable: false),
            repaint: _painterTick,
            particleCount: _particleCount,
          ),
          const SizedBox(height: 12),
          _ControlsPanel(
            viewMode: _viewMode,
            backendKind: _singleBackendKind,
            particleCount: _particleCount,
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

  Float32List get particles => backend.particles;

  Duration step(
    double dtSeconds, {
    GalaxyStepConfig config = const GalaxyStepConfig(),
  }) {
    final duration = backend.step(dtSeconds, config: config);
    smoothedStepMicros = _smooth(
      smoothedStepMicros,
      duration.inMicroseconds.toDouble(),
    );
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

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.viewMode,
    required this.particleCount,
    required this.tickFps,
    required this.compareSummary,
  });

  final GalaxyBenchmarkViewMode viewMode;
  final int particleCount;
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
          label: 'Particle buffer',
          value: '$particleCount x $galaxyParticleStride float32',
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
  });

  final List<_BenchmarkSceneState> scenes;
  final Listenable repaint;
  final int particleCount;

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
  });

  final _BenchmarkSceneState scene;
  final Listenable repaint;
  final int particleCount;

  @override
  Widget build(BuildContext context) {
    final particlesPerSecond =
        scene.smoothedStepMicros == 0
            ? 0
            : (particleCount * 1000000) / scene.smoothedStepMicros;

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
                  label: 'Step',
                  value:
                      '${(scene.smoothedStepMicros / 1000).toStringAsFixed(3)} ms',
                ),
                _SceneMetricChip(
                  label: 'Particles / sec',
                  value: particlesPerSecond.toStringAsFixed(0),
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
                      label: 'Same renderer, same dt, same seed',
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
    required this.timeScale,
    required this.swirl,
    required this.centerPull,
    required this.onViewModeChanged,
    required this.onBackendChanged,
    required this.onParticleCountChanged,
    required this.onTimeScaleChanged,
    required this.onSwirlChanged,
    required this.onCenterPullChanged,
  });

  final GalaxyBenchmarkViewMode viewMode;
  final GalaxyComputeBackend backendKind;
  final int particleCount;
  final double timeScale;
  final double swirl;
  final double centerPull;
  final ValueChanged<GalaxyBenchmarkViewMode?> onViewModeChanged;
  final ValueChanged<GalaxyComputeBackend?> onBackendChanged;
  final ValueChanged<int> onParticleCountChanged;
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                galaxyParticlePresets
                    .map(
                      (preset) => ChoiceChip(
                        label: Text('$preset particles'),
                        selected: particleCount == preset,
                        onSelected: (_) => onParticleCountChanged(preset),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Time scale',
            value: timeScale,
            min: 0.6,
            max: 1.8,
            divisions: 12,
            valueLabel: timeScale.toStringAsFixed(2),
            onChanged: onTimeScaleChanged,
          ),
          _SliderRow(
            label: 'Swirl',
            value: swirl,
            min: 0.8,
            max: 2.0,
            divisions: 24,
            valueLabel: swirl.toStringAsFixed(2),
            onChanged: onSwirlChanged,
          ),
          _SliderRow(
            label: 'Center pull',
            value: centerPull,
            min: 1.0,
            max: 2.4,
            divisions: 28,
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
                'Compare mode reseeds both backends together so they start from the same particle field.',
          ),
          const _NoteRow(
            icon: Icons.call_merge,
            text:
                'The FFI path uses one batched native call per frame, not one call per particle.',
          ),
          const _NoteRow(
            icon: Icons.storage,
            text:
                'The native backend exposes a Float32List view over native memory, so the renderer reads directly from the same buffer.',
          ),
          const _NoteRow(
            icon: Icons.warning_amber,
            text:
                'This compares simulation-step cost, not shader throughput, GPU time, or full app power usage.',
          ),
        ],
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({required this.particles, required Listenable repaint})
    : super(repaint: repaint);

  final Float32List particles;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final scale = math.min(size.width, size.height) * 0.42;

    final backgroundPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF03060C),
              Color(0xFF050A13),
              Color(0xFF090D19),
            ],
          ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final haloPaint =
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFE29A).withValues(alpha: 0.24),
              const Color(0xFF4FD5FF).withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.28, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: scale * 0.92));
    canvas.drawCircle(center, scale * 0.92, haloPaint);

    for (
      var offset = 0;
      offset < particles.length;
      offset += galaxyParticleStride
    ) {
      final x = particles[offset].toDouble();
      final y = particles[offset + 1].toDouble();
      final vx = particles[offset + 2].toDouble();
      final vy = particles[offset + 3].toDouble();
      final position = Offset(center.dx + x * scale, center.dy + y * scale);
      final distance = math.sqrt((x * x) + (y * y)).clamp(0.0, 1.25);
      final speed = math.min(math.sqrt((vx * vx) + (vy * vy)), 2.0);
      final warmth = (1.0 - (distance / 1.25)).clamp(0.0, 1.0);
      final hue = lerpDouble(195, 40, warmth)!;
      final saturation = lerpDouble(0.52, 0.78, warmth)!;
      final lightness = lerpDouble(0.55, 0.76, speed / 2.0)!;
      final glowColor =
          HSLColor.fromAHSL(
            0.22 + (warmth * 0.28),
            hue,
            saturation,
            lightness,
          ).toColor();
      final radius = 0.9 + (speed * 0.55) + (warmth * 0.65);

      canvas.drawCircle(
        position,
        radius * 2.4,
        Paint()..color = glowColor.withValues(alpha: 0.08),
      );
      canvas.drawCircle(position, radius, Paint()..color = glowColor);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return !identical(oldDelegate.particles, particles);
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
    return SizedBox(
      width: 200,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
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
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
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

String _sceneTag(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'No FFI',
    GalaxyComputeBackend.cFfi => 'Native batch step',
  };
}
