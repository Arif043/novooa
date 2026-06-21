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
              child: _TabContent(tab: tab),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab});

  final RootTab tab;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroIcon(icon: tab.icon),
        const SizedBox(height: 18),
        Text(tab.title, style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 10),
        Text(tab.content, textAlign: TextAlign.center),
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: SyscatTheme.primaryOrange.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Icon(icon, size: 42, color: SyscatTheme.primaryOrangeDark),
      ),
    );
  }
}
