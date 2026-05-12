part of '../galaxy_benchmark_page.dart';


// Summary metrics and per-backend preview cards.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

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
