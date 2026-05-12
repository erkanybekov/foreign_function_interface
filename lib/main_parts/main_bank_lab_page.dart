part of '../main.dart';

// Live FFI Calls tab: state and orchestration for interactive demos.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// Third tab: hands-on calls into native code (add, PAN/IBAN validation, risk struct) via [BankLabService].
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
    return AdaptivePageScaffold(
      title: 'Live FFI Calls',
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
