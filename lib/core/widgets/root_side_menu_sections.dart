import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/assets.dart';
import '../../root_tab.dart';
import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';
import 'user_greeting.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({
    super.key,
    this.currentUserName,
    this.clock = DateTime.now,
  });

  final String? currentUserName;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      // Wrap: Der Gruß steht rechts neben dem Logo und rutscht nur bei
      // schmalem Menü oder großer Schrift darunter.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Image.asset(
            Assets.iconsFullv2Transparent,
            width: 180,
            semanticLabel: 'novooa',
          ),
          UserGreeting(displayName: currentUserName, now: clock()),
        ],
      ),
    );
  }
}

class SideMenuTabList extends StatelessWidget {
  const SideMenuTabList({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < tabs.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _SideMenuTile(
            tab: tabs[index],
            isSelected: index == selectedIndex,
            onTap: () => onSelected(index),
          ),
        ],
      ],
    );
  }
}

class _SideMenuTile extends StatelessWidget {
  const _SideMenuTile({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final RootTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      leading: SideMenuIcon(
        icon: tab.icon,
        backgroundColor: _iconColor,
        foregroundColor: SyscatTheme.iconActive,
      ),
      title: Text(tab.title),
      trailing: isSelected
          ? const Icon(CupertinoIcons.check_mark, size: 18)
          : null,
      onTap: onTap,
    );
  }

  Color get _iconColor {
    return switch (tab.path) {
      '/files' || '/knowledge-base' => SyscatTheme.backgroundDark,
      '/schedule' || '/tasks' => SyscatTheme.primaryOrange,
      '/activity' || '/results' || '/settings' => SyscatTheme.info,
      _ => SyscatTheme.primaryOrange,
    };
  }
}

class SideMenuIcon extends StatelessWidget {
  const SideMenuIcon({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Icon(icon, color: foregroundColor, size: 20),
    );
  }
}
