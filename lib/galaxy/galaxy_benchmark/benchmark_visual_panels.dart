part of '../galaxy_benchmark_page.dart';


// Visual effect picker and Nebula/Aurora shader toggle.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

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
