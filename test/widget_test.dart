import 'package:bank_core_ffi/bank_core_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foreign_function_interface/galaxy/galaxy_simulation.dart';
import 'package:foreign_function_interface/main.dart';

void main() {
  testWidgets('Bank FFI lab renders validators and risk score', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bank FFI Lab'), findsOneWidget);
    expect(find.text('Galaxy Benchmark'), findsOneWidget);
    expect(find.textContaining('Native banking core'), findsOneWidget);
    expect(find.text('PAN VALID'), findsOneWidget);
    expect(find.text('IBAN VALID'), findsOneWidget);
  });

  testWidgets('PAN status reacts to user input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.pump();

    expect(find.text('PAN INVALID'), findsOneWidget);
  });

  testWidgets('Galaxy benchmark opens in compare mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galaxy Benchmark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.text('Galaxy Benchmark'), findsWidgets);
    expect(find.text('Reset field'), findsOneWidget);
    expect(find.text('Compare mode'), findsOneWidget);
    expect(find.text('Pure Dart'), findsWidgets);
    expect(find.text('C via FFI'), findsWidgets);
  });
}

GalaxySimulationBackend _fakeBenchmarkBackendBuilder(
  GalaxyComputeBackend kind,
  int particleCount,
  GalaxyStepConfig config,
  BankCoreFfi? core,
) {
  return DartGalaxySimulationBackend(
    particleCount: particleCount > 128 ? 128 : particleCount,
    config: config,
  );
}

class _FakeBankLabService implements BankLabService {
  @override
  int add(int a, int b) => a + b;

  @override
  bool isValidPan(String pan) => pan.startsWith('4') && pan.length > 8;

  @override
  bool isValidIban(String iban) => iban.startsWith('GB82');

  @override
  String nativeErrorMessage(int code) {
    return 'native argument is outside the accepted range';
  }

  @override
  RiskScore scoreTransaction(TransactionRiskInput input) {
    return const RiskScore(
      score: 85,
      decision: RiskDecision.block,
      flags: <RiskFlag>{
        RiskFlag.highAmount,
        RiskFlag.newAccount,
        RiskFlag.failedAttempts,
      },
    );
  }
}
