import 'package:flutter/material.dart';

import 'adaptive_page_app_bar.dart';

/// [Scaffold] with [AdaptivePageAppBar] (Cupertino bar on Apple platforms).
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
