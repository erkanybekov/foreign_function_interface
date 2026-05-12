import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_targets.dart';

/// Toolbar action: icon+label row on Apple platforms, [TextButton.icon] elsewhere.
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
        minimumSize: Size.zero,
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
