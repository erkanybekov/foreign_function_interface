part of '../main.dart';

// Live lab UI: header, validation, risk sliders, roadmap, guardrails.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.addResult, required this.errorMessage});

  final int addResult;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live native banking examples',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Flutter calls a small C library. Each card is a concrete example: scalar, strings, structs, and native error mapping.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final tileWidth =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    <Widget>[
                          _FfiPatternTile(
                            icon: Icons.functions,
                            title: 'Scalar call',
                            call: 'bank_add(1200, 37)',
                            result: '$addResult',
                          ),
                          const _FfiPatternTile(
                            icon: Icons.short_text,
                            title: 'String call',
                            call: 'PAN / IBAN -> char*',
                            result: 'C returns valid / invalid',
                          ),
                          const _FfiPatternTile(
                            icon: Icons.view_in_ar,
                            title: 'Struct call',
                            call: 'TransactionRiskInput*',
                            result: 'C fills RiskScore*',
                          ),
                          _FfiPatternTile(
                            icon: Icons.report_gmailerrorred,
                            title: 'Error mapping',
                            call: 'native code -2',
                            result: errorMessage,
                          ),
                        ]
                        .map((tile) => SizedBox(width: tileWidth, child: tile))
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({
    required this.panController,
    required this.ibanController,
    required this.panValid,
    required this.ibanValid,
    required this.onChanged,
  });

  final TextEditingController panController;
  final TextEditingController ibanController;
  final bool panValid;
  final bool ibanValid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '1. Strings: native validators',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Dart sends UTF-8 strings to C. C checks the value and returns 1 or 0.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: panController,
            decoration: InputDecoration(
              labelText: 'PAN / card number',
              helperText: 'Luhn check in C. Spaces and dashes are accepted.',
              prefixIcon: const Icon(Icons.credit_card),
              suffixIcon: _StatusIcon(valid: panValid),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ibanController,
            decoration: InputDecoration(
              labelText: 'IBAN',
              helperText: 'MOD-97 check in C. Lowercase is normalized.',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              suffixIcon: _StatusIcon(valid: ibanValid),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const Chip(
                avatar: Icon(Icons.memory, size: 18),
                label: Text('Native call: char*'),
                visualDensity: VisualDensity.compact,
              ),
              _StatusChip(label: 'PAN', valid: panValid),
              _StatusChip(label: 'IBAN', valid: ibanValid),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskPanel extends StatelessWidget {
  const _RiskPanel({
    required this.amountCents,
    required this.accountAgeDays,
    required this.failedAttempts24h,
    required this.foreignCountry,
    required this.nightTime,
    required this.riskScore,
    required this.onAmountChanged,
    required this.onAccountAgeChanged,
    required this.onFailedAttemptsChanged,
    required this.onForeignCountryChanged,
    required this.onNightTimeChanged,
  });

  final int amountCents;
  final int accountAgeDays;
  final int failedAttempts24h;
  final bool foreignCountry;
  final bool nightTime;
  final RiskScore riskScore;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<int> onAccountAgeChanged;
  final ValueChanged<int> onFailedAttemptsChanged;
  final ValueChanged<bool> onForeignCountryChanged;
  final ValueChanged<bool> onNightTimeChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '2. Structs: transaction risk',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Chip(
                avatar: Icon(Icons.memory, size: 18),
                label: Text('struct*'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dart fills a native input struct. C returns score, decision, and reason flags.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _NativeResultCard(riskScore: riskScore),
          const SizedBox(height: 12),
          Text('Dart input', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _NumberSlider(
            label: 'Amount',
            valueLabel: _formatMoney(amountCents),
            value: amountCents.toDouble(),
            min: 1000,
            max: 3000000,
            divisions: 120,
            onChanged: (value) => onAmountChanged(value.round()),
          ),
          _NumberSlider(
            label: 'Account age',
            valueLabel: '$accountAgeDays days',
            value: accountAgeDays.toDouble(),
            min: 0,
            max: 365,
            divisions: 73,
            onChanged: (value) => onAccountAgeChanged(value.round()),
          ),
          _NumberSlider(
            label: 'Failed attempts',
            valueLabel: '$failedAttempts24h',
            value: failedAttempts24h.toDouble(),
            min: 0,
            max: 6,
            divisions: 6,
            onChanged: (value) => onFailedAttemptsChanged(value.round()),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foreign country'),
            value: foreignCountry,
            onChanged: onForeignCountryChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Night-time transaction'),
            value: nightTime,
            onChanged: onNightTimeChanged,
          ),
          const SizedBox(height: 8),
          Text(
            'Native reason flags',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                riskScore.flags.isEmpty
                    ? const <Widget>[Chip(label: Text('none'))]
                    : riskScore.flags
                        .map((flag) => Chip(label: Text(_riskFlagLabel(flag))))
                        .toList(),
          ),
        ],
      ),
    );
  }
}

class _LearningRoadmapPanel extends StatelessWidget {
  const _LearningRoadmapPanel();

  static const List<({IconData icon, String title, String body})> topics = [
    (
      icon: Icons.hub,
      title: 'C ABI',
      body: 'Exported symbols, dynamic libraries, and stable C signatures.',
    ),
    (
      icon: Icons.category,
      title: 'Native types',
      body: 'int32, char*, structs, opaque handles, arrays, and buffers.',
    ),
    (
      icon: Icons.storage,
      title: 'Memory',
      body: 'Dart allocates native inputs and frees them after each call.',
    ),
    (
      icon: Icons.speed,
      title: 'Performance',
      body: 'Batch heavy work and move long native calls off the UI isolate.',
    ),
    (
      icon: Icons.inventory_2,
      title: 'Packaging',
      body: 'Android .so, Apple frameworks, Windows .dll, and Linux .so.',
    ),
    (
      icon: Icons.security,
      title: 'Banking fit',
      body: 'Wrap audited SDKs, native risk engines, OCR, and device signals.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('FFI roadmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    topics
                        .map(
                          (topic) => SizedBox(
                            width:
                                narrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 10) / 2,
                            child: _RoadmapTile(
                              icon: topic.icon,
                              title: topic.title,
                              body: topic.body,
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Banking guardrails',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _GuardrailRow(
            icon: Icons.no_encryption_gmailerrorred,
            text: 'Do not write custom crypto in demo C code.',
          ),
          const _GuardrailRow(
            icon: Icons.visibility_off,
            text: 'Do not log PAN, IBAN, keys, tokens, or full risk payloads.',
          ),
          const _GuardrailRow(
            icon: Icons.verified_user,
            text: 'Use FFI to wrap audited native SDKs and verified libraries.',
          ),
        ],
      ),
    );
  }
}
