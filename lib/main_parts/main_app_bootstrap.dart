part of '../main.dart';

// Entrypoint, [BankLabService], [MyApp], and default FFI wiring.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// Runs the Material demo shell ([MyApp]).
void main() {
  runApp(const MyApp());
}

/// Contract for the banking FFI demos used by [BankFfiLabPage] and tests.
///
/// Implemented by [FfiBankLabService], which delegates to [BankCoreFfi].
abstract class BankLabService {
  int add(int a, int b);
  bool isValidPan(String pan);
  bool isValidIban(String iban);
  RiskScore scoreTransaction(TransactionRiskInput input);
  String nativeErrorMessage(int code);
}

/// Default [BankLabService] backed by [BankCoreFfi] (C/Rust native code).
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

/// Root widget: theme, title, and [_HomeShell] with optional DI for tests/benchmarks.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.service,
    this.core,
    this.benchmarkBackendBuilder,
  });

  final BankLabService? service;
  final BankCoreFfi? core;
  final GalaxyBenchmarkBackendBuilder? benchmarkBackendBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFI Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: _HomeShell(
        service: service,
        core: core,
        benchmarkBackendBuilder: benchmarkBackendBuilder,
      ),
    );
  }
}
