import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';

import 'galaxy/galaxy_benchmark_page.dart';

void main() {
  runApp(const MyApp());
}

abstract class BankLabService {
  int add(int a, int b);
  bool isValidPan(String pan);
  bool isValidIban(String iban);
  RiskScore scoreTransaction(TransactionRiskInput input);
  String nativeErrorMessage(int code);
}

class FfiBankLabService implements BankLabService {
  FfiBankLabService({BankCoreFfi? core}) : _core = core ?? BankCoreFfi();

  final BankCoreFfi _core;

  @override
  int add(int a, int b) => _core.add(a, b);

  @override
  bool isValidPan(String pan) => _core.isValidPan(pan);

  @override
  bool isValidIban(String iban) => _core.isValidIban(iban);

  @override
  RiskScore scoreTransaction(TransactionRiskInput input) {
    return _core.scoreTransaction(input);
  }

  @override
  String nativeErrorMessage(int code) => _core.nativeErrorMessage(code);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.service, this.core});

  final BankLabService? service;
  final BankCoreFfi? core;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank FFI Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: _HomeShell(service: service, core: core),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.service, required this.core});

  final BankLabService? service;
  final BankCoreFfi? core;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_selectedIndex) {
        0 => BankFfiLabPage(service: widget.service),
        _ => GalaxyBenchmarkPage(core: widget.core),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.account_balance),
            label: 'Bank Lab',
          ),
          NavigationDestination(
            icon: Icon(Icons.blur_on),
            label: 'Galaxy Benchmark',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class BankFfiLabPage extends StatefulWidget {
  const BankFfiLabPage({super.key, this.service});

  final BankLabService? service;

  @override
  State<BankFfiLabPage> createState() => _BankFfiLabPageState();
}

class _BankFfiLabPageState extends State<BankFfiLabPage> {
  late final BankLabService _service = widget.service ?? FfiBankLabService();
  final TextEditingController _panController = TextEditingController(
    text: '4111 1111 1111 1111',
  );
  final TextEditingController _ibanController = TextEditingController(
    text: 'GB82 WEST 1234 5698 7654 32',
  );

  int _amountCents = 1250000;
  int _accountAgeDays = 24;
  int _failedAttempts24h = 3;
  bool _foreignCountry = true;
  bool _nightTime = true;

  int _nativeAddResult = 0;
  bool _panValid = false;
  bool _ibanValid = false;
  String _nativeErrorExample = '';
  RiskScore _riskScore = const RiskScore(
    score: 0,
    decision: RiskDecision.approve,
    flags: <RiskFlag>{},
  );
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _refreshLab(notify: false);
  }

  @override
  void dispose() {
    _panController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  void _refreshLab({bool notify = true}) {
    void refresh() {
      try {
        _nativeAddResult = _service.add(1200, 37);
        _panValid = _service.isValidPan(_panController.text);
        _ibanValid = _service.isValidIban(_ibanController.text);
        _nativeErrorExample = _service.nativeErrorMessage(-2);
        _riskScore = _service.scoreTransaction(
          TransactionRiskInput(
            amountCents: _amountCents,
            accountAgeDays: _accountAgeDays,
            failedAttempts24h: _failedAttempts24h,
            foreignCountry: _foreignCountry,
            nightTime: _nightTime,
          ),
        );
        _lastError = null;
      } catch (error) {
        _lastError = error.toString();
      }
    }

    if (notify) {
      setState(refresh);
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank FFI Lab'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeaderPanel(
            addResult: _nativeAddResult,
            errorMessage: _nativeErrorExample,
          ),
          const SizedBox(height: 12),
          if (_lastError != null) _ErrorPanel(message: _lastError!),
          _ValidationPanel(
            panController: _panController,
            ibanController: _ibanController,
            panValid: _panValid,
            ibanValid: _ibanValid,
            onChanged: (_) => _refreshLab(),
          ),
          const SizedBox(height: 12),
          _RiskPanel(
            amountCents: _amountCents,
            accountAgeDays: _accountAgeDays,
            failedAttempts24h: _failedAttempts24h,
            foreignCountry: _foreignCountry,
            nightTime: _nightTime,
            riskScore: _riskScore,
            onAmountChanged: (value) {
              _amountCents = value;
              _refreshLab();
            },
            onAccountAgeChanged: (value) {
              _accountAgeDays = value;
              _refreshLab();
            },
            onFailedAttemptsChanged: (value) {
              _failedAttempts24h = value;
              _refreshLab();
            },
            onForeignCountryChanged: (value) {
              _foreignCountry = value;
              _refreshLab();
            },
            onNightTimeChanged: (value) {
              _nightTime = value;
              _refreshLab();
            },
          ),
          const SizedBox(height: 12),
          const _LearningRoadmapPanel(),
          const SizedBox(height: 12),
          const _SecurityPanel(),
        ],
      ),
    );
  }
}

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
                  'Native banking core loaded through dart:ffi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricChip(
                label: 'bank_add(1200, 37)',
                value: '$addResult',
                icon: Icons.functions,
              ),
              _MetricChip(
                label: 'C ABI',
                value: 'int32 + char* + struct',
                icon: Icons.memory,
              ),
              _MetricChip(
                label: 'Error -2',
                value: errorMessage,
                icon: Icons.report_gmailerrorred,
              ),
            ],
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
            'Native validators',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: panController,
            decoration: InputDecoration(
              labelText: 'PAN / card number',
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
            children: <Widget>[
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
                  'Struct-based transaction scoring',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _DecisionBadge(decision: riskScore.decision),
            ],
          ),
          const SizedBox(height: 12),
          _ScoreBar(score: riskScore.score),
          const SizedBox(height: 8),
          Text('Risk score: ${riskScore.score}/100'),
          const SizedBox(height: 12),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foreign country'),
            value: foreignCountry,
            onChanged: onForeignCountryChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Night-time transaction'),
            value: nightTime,
            onChanged: onNightTimeChanged,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                riskScore.flags
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
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
