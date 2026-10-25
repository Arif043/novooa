import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/assets.dart';
import '../../root_tab.dart';
import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key, this.currentUserName});

  final String? currentUserName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            Assets.iconsFullv2Transparent,
            width: 180,
            semanticLabel: 'novooa',
          ),
          const SizedBox(height: AppSpacing.sm),
          _UserGreeting(displayName: currentUserName),
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

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim() ?? '';
    return Text(
      name.isEmpty
          ? LocaleKeys.navigation_greeting.tr()
          : LocaleKeys.navigation_greeting_named.tr(namedArgs: {'name': name}),
      style: Theme.of(context).textTheme.titleMedium,
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
      '/activity' || '/settings' => SyscatTheme.info,
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
