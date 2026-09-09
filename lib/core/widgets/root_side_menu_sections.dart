import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';

import '../../root_tab.dart';
import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key, this.showCurrentUserProfile = true});

  final bool showCurrentUserProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const _BrandMark(),
          const SizedBox(width: AppSpacing.md),
          if (showCurrentUserProfile) const _CurrentUserGreeting(),
        ],
      ),
    );
  }
}

class _CurrentUserGreeting extends StatefulWidget {
  const _CurrentUserGreeting();

  @override
  State<_CurrentUserGreeting> createState() => _CurrentUserGreetingState();
}

class _CurrentUserGreetingState extends State<_CurrentUserGreeting> {
  late final Future _profileFuture = serviceLocator<GetCurrentUserProfile>()
      .call();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.data case Success(success: final user)) {
          return Text(
            'Hey ${user.displayName}',
            style: Theme.of(context).textTheme.titleLarge,
          );
        }
        return const SizedBox.shrink();
      },
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: SyscatTheme.activeNavigationGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SyscatTheme.primaryOrange.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          CupertinoIcons.arrow_left,
          color: SyscatTheme.iconActive,
          size: 30,
        ),
      ),
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
