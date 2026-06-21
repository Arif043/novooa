import 'package:flutter/material.dart';

import '../theme/syscat_theme.dart';
import '../../root_tab.dart';

class RootStage extends StatelessWidget {
  const RootStage({super.key, required this.tab});

  final RootTab tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: SyscatTheme.glassPanelDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: tab.builder(context),
            ),
          ),
        ),
      ),
    );
  }
}
