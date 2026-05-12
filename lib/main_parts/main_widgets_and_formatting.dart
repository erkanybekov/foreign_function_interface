part of '../main.dart';

// Shared chips, tiles, code blocks, chrome widgets, and string helpers.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

class _GuidePill extends StatelessWidget {
  const _GuidePill({required this.icon, required this.text});

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

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleUsageCard extends StatelessWidget {
  const _ExampleUsageCard({
    required this.icon,
    required this.example,
    required this.boundary,
    required this.usage,
    required this.fit,
    required this.dartCode,
    required this.nativeCode,
  });

  final IconData icon;
  final String example;
  final String boundary;
  final String usage;
  final String fit;
  final String dartCode;
  final String nativeCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 22, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    example,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _UsageLine(label: 'Boundary', value: boundary),
            _UsageLine(label: 'Usage', value: usage),
            _UsageLine(label: 'Fit', value: fit),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                final width =
                    narrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;
                final blocks = <Widget>[
                  _LabeledCodeBlock(label: 'Dart usage', code: dartCode),
                  _LabeledCodeBlock(label: 'Native boundary', code: nativeCode),
                ];

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      blocks
                          .map((block) => SizedBox(width: width, child: block))
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageLine extends StatelessWidget {
  const _UsageLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _LabeledCodeBlock extends StatelessWidget {
  const _LabeledCodeBlock({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        _CodeBlock(code: code, maxLines: 3),
      ],
    );
  }
}

class _BasicStepCard extends StatelessWidget {
  const _BasicStepCard({
    required this.title,
    required this.body,
    required this.code,
  });

  final String title;
  final String body;
  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 10),
            _CodeBlock(code: code),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, this.maxLines = 2});

  final String code;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            code,
            maxLines: maxLines,
            style: const TextStyle(
              color: Color(0xFFE6EEF5),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionColumn extends StatelessWidget {
  const _DecisionColumn({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('- '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card container used across guide, setup, bank lab, and antifraud screens.
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

class _FfiPatternTile extends StatelessWidget {
  const _FfiPatternTile({
    required this.icon,
    required this.title,
    required this.call,
    required this.result,
  });

  final IconData icon;
  final String title;
  final String call;
  final String result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(call, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    result,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.valid});

  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Icon(
      valid ? Icons.check_circle : Icons.cancel,
      color: valid ? const Color(0xFF008A5B) : const Color(0xFFC43C3C),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ${valid ? 'VALID' : 'INVALID'}'),
      backgroundColor:
          valid ? const Color(0xFFE0F4EC) : const Color(0xFFFFE6E6),
      side: BorderSide.none,
    );
  }
}

class _DecisionBadge extends StatelessWidget {
  const _DecisionBadge({required this.decision});

  final RiskDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = switch (decision) {
      RiskDecision.approve => const Color(0xFF008A5B),
      RiskDecision.review => const Color(0xFFB97900),
      RiskDecision.block => const Color(0xFFC43C3C),
    };

    return Chip(
      label: Text(_decisionLabel(decision)),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}

class _NativeResultCard extends StatelessWidget {
  const _NativeResultCard({required this.riskScore});

  final RiskScore riskScore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.output, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Native output',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _DecisionBadge(decision: riskScore.decision),
              ],
            ),
            const SizedBox(height: 12),
            _ScoreBar(score: riskScore.score),
            const SizedBox(height: 8),
            Text('Risk score: ${riskScore.score}/100'),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: 10,
        backgroundColor: const Color(0xFFE6E8EB),
        color:
            score >= 70
                ? const Color(0xFFC43C3C)
                : score >= 35
                ? const Color(0xFFB97900)
                : const Color(0xFF008A5B),
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[Expanded(child: Text(label)), Text(valueLabel)]),
        Slider.adaptive(
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

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardrailRow extends StatelessWidget {
  const _GuardrailRow({required this.icon, required this.text});

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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6E6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      ),
    );
  }
}

String _formatMoney(int amountCents) {
  final dollars = amountCents ~/ 100;
  final cents = amountCents % 100;
  return '\$$dollars.${cents.toString().padLeft(2, '0')}';
}

String _decisionLabel(RiskDecision decision) {
  return switch (decision) {
    RiskDecision.approve => 'APPROVE',
    RiskDecision.review => 'REVIEW',
    RiskDecision.block => 'BLOCK',
  };
}

String _riskFlagLabel(RiskFlag flag) {
  return switch (flag) {
    RiskFlag.highAmount => 'high amount',
    RiskFlag.newAccount => 'new account',
    RiskFlag.failedAttempts => 'failed attempts',
    RiskFlag.foreignCountry => 'foreign country',
    RiskFlag.nightTime => 'night-time',
  };
}
