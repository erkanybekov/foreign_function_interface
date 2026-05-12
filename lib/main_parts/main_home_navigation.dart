part of '../main.dart';

// Bottom/tab bar chrome for mobile vs Material navigation.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

class _HomeDestination {
  const _HomeDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _AdaptiveBottomNavigationBar extends StatelessWidget {
  const _AdaptiveBottomNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<_HomeDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isApplePlatform(context)) {
      return CupertinoTabBar(
        currentIndex: selectedIndex,
        activeColor: colorScheme.primary,
        inactiveColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        items:
            destinations
                .map(
                  (destination) => BottomNavigationBarItem(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
                )
                .toList(),
        onTap: onDestinationSelected,
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations:
          destinations
              .map(
                (destination) => NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                ),
              )
              .toList(),
      onDestinationSelected: onDestinationSelected,
    );
  }
}
