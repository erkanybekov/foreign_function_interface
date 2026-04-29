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

    expect(find.text('FFI Guide'), findsOneWidget);
    expect(find.textContaining('FFI lets Flutter call native'), findsOneWidget);
    expect(find.text('Bank Lab'), findsOneWidget);
    expect(find.text('AntiFraud Fit'), findsOneWidget);
    expect(find.text('Cosmos Benchmark'), findsOneWidget);

    await tester.tap(find.text('Bank Lab'));
    await tester.pumpAndSettle();

    expect(find.text('Bank FFI Lab'), findsOneWidget);
    expect(find.textContaining('Native banking core'), findsOneWidget);
    expect(find.text('PAN VALID'), findsOneWidget);
    expect(find.text('IBAN VALID'), findsOneWidget);
  });

  testWidgets('Guide explains FFI basics and best practices', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Implementation basics'), findsOneWidget);
    expect(find.text('1. Native C ABI'), findsOneWidget);
    expect(find.text('2. Dart binding'), findsOneWidget);
    expect(find.text('3. Public facade'), findsOneWidget);
    expect(find.text('4. Memory contract'), findsOneWidget);
    expect(find.text('Best practices'), findsOneWidget);
    expect(find.text('Do'), findsOneWidget);
    expect(find.text('Do not'), findsOneWidget);
  });

  testWidgets('PAN status reacts to user input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bank Lab'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.pump();

    expect(find.text('PAN INVALID'), findsOneWidget);
  });

  testWidgets('Cosmos benchmark opens in compare mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cosmos Benchmark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.text('Cosmos Benchmark'), findsWidgets);
    expect(find.text('Benchmark lesson'), findsOneWidget);
    expect(find.text('Reset field'), findsOneWidget);
    expect(find.text('Compare mode'), findsOneWidget);
    expect(find.text('Pure Dart', skipOffstage: false), findsWidgets);
    expect(find.text('C via FFI', skipOffstage: false), findsWidgets);
  });

  testWidgets('AntiFraud fit screen explains where FFI belongs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        service: _FakeBankLabService(),
        benchmarkBackendBuilder: _fakeBenchmarkBackendBuilder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AntiFraud Fit'));
    await tester.pumpAndSettle();

    expect(find.text('AntiFraud FFI Fit'), findsOneWidget);
    expect(find.textContaining('server-side fraud analytics'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Fit matrix'), 300);
    expect(find.text('Fit matrix'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Bad idea'), 300);
    expect(find.text('Bad idea'), findsOneWidget);
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
