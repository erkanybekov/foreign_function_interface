part of '../main.dart';

// Reusable two-column grid for guide and setup cards.
//
// Extracted from the former monolithic `main.dart` for readability; behavior is unchanged.

class _GuideGridPanel extends StatelessWidget {
  const _GuideGridPanel({required this.title, required this.children});

  final String title;
  final List<({IconData icon, String title, String body})> children;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 680;
              final width =
                  narrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    children
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: _GuideTile(
                              icon: item.icon,
                              title: item.title,
                              body: item.body,
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
