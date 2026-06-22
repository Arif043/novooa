import 'package:flutter/material.dart';

import '../../root_tab.dart';

class RootStage extends StatelessWidget {
  const RootStage({super.key, required this.tab});

  final RootTab tab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: tab.builder(context),
        ),
      ),
    );
  }
}
