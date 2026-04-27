import 'dart:ui' show lerpDouble;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'galaxy_simulation.dart';

const List<int> galaxyParticlePresets = <int>[768, 1536, 3072];

class GalaxyBenchmarkPage extends StatefulWidget {
  const GalaxyBenchmarkPage({super.key, this.core});

  final BankCoreFfi? core;

  @override
  State<GalaxyBenchmarkPage> createState() => _GalaxyBenchmarkPageState();
}

class _GalaxyBenchmarkPageState extends State<GalaxyBenchmarkPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ValueNotifier<int> _painterTick;
  late GalaxySimulationBackend _backend;
  BankCoreFfi? _core;

  GalaxyComputeBackend _backendKind = GalaxyComputeBackend.dart;
  int _particleCount = 1536;
  double _timeScale = 1.0;
  double _swirl = 1.35;
  double _centerPull = 1.6;
  double _smoothedStepMicros = 0;
  double _smoothedFrameMicros = 16667;
  int _sampleCount = 0;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _painterTick = ValueNotifier<int>(0);
    _backend = _createBackend(_backendKind, particleCount: _particleCount);
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _painterTick.dispose();
    _backend.dispose();
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

  GalaxySimulationBackend _createBackend(
    GalaxyComputeBackend kind, {
    required int particleCount,
  }) {
    return switch (kind) {
      GalaxyComputeBackend.dart => DartGalaxySimulationBackend(
        particleCount: particleCount,
        config: _stepConfig,
      ),
      GalaxyComputeBackend.cFfi => FfiGalaxySimulationBackend(
        core: _resolvedCore,
        particleCount: particleCount,
        config: _stepConfig,
      ),
    };
  }

  void _replaceBackend(GalaxyComputeBackend kind) {
    final nextBackend = _createBackend(kind, particleCount: _particleCount);
    final previousBackend = _backend;
    setState(() {
      _backend = nextBackend;
      _backendKind = kind;
      _resetMetrics();
    });
    previousBackend.dispose();
  }

  void _reseedBackend() {
    setState(() {
      _backend.reseed(_particleCount, config: _stepConfig);
      _resetMetrics();
    });
  }

  void _resetMetrics() {
    _lastElapsed = null;
    _sampleCount = 0;
    _smoothedStepMicros = 0;
    _smoothedFrameMicros = 16667;
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
    final stepDuration = _backend.step(dtSeconds, config: _stepConfig);

    _smoothedFrameMicros = _smooth(_smoothedFrameMicros, rawFrameMicros);
    _smoothedStepMicros = _smooth(
      _smoothedStepMicros,
      stepDuration.inMicroseconds.toDouble(),
    );
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

  @override
  Widget build(BuildContext context) {
    final tickFps = 1000000 / _smoothedFrameMicros;
    final particlesPerSecond =
        _smoothedStepMicros == 0
            ? 0
            : (_particleCount * 1000000) / _smoothedStepMicros;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galaxy Benchmark'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _reseedBackend,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset field'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _BenchmarkHero(
            particles: _backend.particles,
            repaint: _painterTick,
            backendKind: _backendKind,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricCard(
                label: 'Backend step',
                value: '${(_smoothedStepMicros / 1000).toStringAsFixed(3)} ms',
              ),
              _MetricCard(
                label: 'Tick rate',
                value: '${tickFps.toStringAsFixed(1)} fps',
              ),
              _MetricCard(
                label: 'Particles / sec',
                value: particlesPerSecond.toStringAsFixed(0),
              ),
              _MetricCard(
                label: 'Buffer',
                value: '$_particleCount x $galaxyParticleStride float32',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ControlsPanel(
            backendKind: _backendKind,
            particleCount: _particleCount,
            timeScale: _timeScale,
            swirl: _swirl,
            centerPull: _centerPull,
            onBackendChanged: (kind) {
              if (kind != null && kind != _backendKind) {
                _replaceBackend(kind);
              }
            },
            onParticleCountChanged: (value) {
              setState(() {
                _particleCount = value;
                _backend.reseed(_particleCount, config: _stepConfig);
                _resetMetrics();
              });
            },
            onTimeScaleChanged: (value) {
              setState(() {
                _timeScale = value;
              });
            },
            onSwirlChanged: (value) {
              setState(() {
                _swirl = value;
                _backend.reseed(_particleCount, config: _stepConfig);
                _resetMetrics();
              });
            },
            onCenterPullChanged: (value) {
              setState(() {
                _centerPull = value;
                _backend.reseed(_particleCount, config: _stepConfig);
                _resetMetrics();
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

class _BenchmarkHero extends StatelessWidget {
  const _BenchmarkHero({
    required this.particles,
    required this.repaint,
    required this.backendKind,
  });

  final Float32List particles;
  final Listenable repaint;
  final GalaxyComputeBackend backendKind;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF04070D)),
        child: AspectRatio(
          aspectRatio: 1.45,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _GalaxyPainter(
                    particles: particles,
                    repaint: repaint,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: _HeroBadge(
                  label:
                      'Renderer: Flutter canvas | Compute: ${_backendLabel(backendKind)}',
                ),
              ),
              const Positioned(
                right: 16,
                bottom: 16,
                child: _HeroBadge(
                  label: 'Fixed visual layer, swapped simulation core',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.backendKind,
    required this.particleCount,
    required this.timeScale,
    required this.swirl,
    required this.centerPull,
    required this.onBackendChanged,
    required this.onParticleCountChanged,
    required this.onTimeScaleChanged,
    required this.onSwirlChanged,
    required this.onCenterPullChanged,
  });

  final GalaxyComputeBackend backendKind;
  final int particleCount;
  final double timeScale;
  final double swirl;
  final double centerPull;
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
          SegmentedButton<GalaxyComputeBackend>(
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
                (value) => onBackendChanged(value.isEmpty ? null : value.first),
          ),
          const SizedBox(height: 12),
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
                'The painter is fixed in Flutter. Only the particle update backend changes.',
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
                'This compares simulation-step cost, not shader throughput or full app power usage.',
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
      width: 188,
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
