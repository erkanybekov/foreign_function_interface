part of '../galaxy_benchmark_page.dart';


// Compare/single mode, particles, substeps, and physics sliders.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

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
