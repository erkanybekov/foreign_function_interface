/// Layout helpers for choosing Cupertino vs Material navigation chrome.
library;
import 'package:flutter/material.dart';

/// True when the host uses iOS or macOS style navigation (Cupertino chrome).
bool isApplePlatform(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

/// Whether a wide layout should show a [NavigationRail] instead of only body content.
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
