import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool isApplePlatform(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

bool usesNavigationRail(BuildContext context, double width) {
  if (width < 900) {
    return false;
  }

  return switch (Theme.of(context).platform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => width >= 1100,
  };
}

class AdaptivePageScaffold extends StatelessWidget {
  const AdaptivePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptivePageAppBar(title: title, actions: actions),
      body: body,
    );
  }
}

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

class AdaptiveAppBarAction extends StatelessWidget {
  const AdaptiveAppBarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform(context)) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minSize: 0,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 19),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
