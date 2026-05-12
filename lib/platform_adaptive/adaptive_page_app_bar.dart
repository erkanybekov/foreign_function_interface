import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_targets.dart';

/// Top bar that follows Apple HIG on iOS/macOS and Material elsewhere.
class AdaptivePageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AdaptivePageAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isApplePlatform(context)) {
      return CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        trailing:
            actions.isEmpty
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
      );
    }

    return AppBar(
      title: Text(title),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      actions: actions,
    );
  }
}
