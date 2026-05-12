part of '../main.dart';

// Root shell: tab index, adaptive layout, and destination switching.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

/// Hosts [MyApp] body: adaptive rail vs stacked navigation and the active tab page.
class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.service,
    required this.core,
    required this.benchmarkBackendBuilder,
  });

  final BankLabService? service;
  final BankCoreFfi? core;
  final GalaxyBenchmarkBackendBuilder? benchmarkBackendBuilder;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

/// Builds the five demo destinations and wires width-based [NavigationRail] vs bottom bar.
class _HomeShellState extends State<_HomeShell> {
  static const List<_HomeDestination> _destinations = <_HomeDestination>[
    _HomeDestination(icon: Icons.route, label: 'Examples'),
    _HomeDestination(icon: Icons.terminal, label: 'Setup'),
    _HomeDestination(icon: Icons.account_balance, label: 'Live Calls'),
    _HomeDestination(icon: Icons.shield, label: 'Usage Map'),
    _HomeDestination(icon: Icons.blur_on, label: 'Performance'),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentPage = switch (_selectedIndex) {
      0 => FfiGuidePage(
        onOpenSetup: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
        onOpenBankLab: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        onOpenAntiFraud: () {
          setState(() {
            _selectedIndex = 3;
          });
        },
        onOpenBenchmark: () {
          setState(() {
            _selectedIndex = 4;
          });
        },
      ),
      1 => const SetupGuidePage(),
      2 => BankFfiLabPage(service: widget.service),
      3 => const AntiFraudFfiFitPage(),
      _ => GalaxyBenchmarkPage(
        core: widget.core,
        backendBuilder: widget.benchmarkBackendBuilder,
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = usesNavigationRail(
          context,
          constraints.maxWidth,
        );

        return Scaffold(
          body:
              useNavigationRail
                  ? Row(
                    children: <Widget>[
                      SafeArea(
                        right: false,
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          labelType: NavigationRailLabelType.all,
                          destinations:
                              _destinations
                                  .map(
                                    (destination) => NavigationRailDestination(
                                      icon: Icon(destination.icon),
                                      label: Text(destination.label),
                                    ),
                                  )
                                  .toList(),
                          onDestinationSelected: _selectDestination,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: currentPage),
                    ],
                  )
                  : currentPage,
          bottomNavigationBar:
              useNavigationRail
                  ? null
                  : _AdaptiveBottomNavigationBar(
                    selectedIndex: _selectedIndex,
                    destinations: _destinations,
                    onDestinationSelected: _selectDestination,
                  ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
