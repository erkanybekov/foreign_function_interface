import 'package:flutter/material.dart';

import 'package:bank_core_ffi/bank_core_ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final BankCoreFfi core;
  late final int addResult;
  late final bool panValid;
  late final bool ibanValid;
  late final RiskScore riskScore;

  @override
  void initState() {
    super.initState();
    core = BankCoreFfi();
    addResult = core.add(1, 2);
    panValid = core.isValidPan('4111 1111 1111 1111');
    ibanValid = core.isValidIban('GB82 WEST 1234 5698 7654 32');
    riskScore = core.scoreTransaction(
      const TransactionRiskInput(
        amountCents: 1250000,
        accountAgeDays: 24,
        failedAttempts24h: 3,
        foreignCountry: true,
        nightTime: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'bank_add(1, 2) = $addResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'PAN valid: $panValid',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'IBAN valid: $ibanValid',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'Risk score: ${riskScore.score}',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
