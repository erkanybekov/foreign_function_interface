part of '../galaxy_benchmark_page.dart';


// Copy and icons for each [GalaxyVisualEffect] option.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

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
