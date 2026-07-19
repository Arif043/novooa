import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';

import '../../root_tab.dart';
import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key});

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
          FutureBuilder(
            future: serviceLocator<GetCurrentUserProfile>().call(),
            builder: (context, snapshot) {
              if (snapshot.data case Success(success: final user)) {
                return Text(
                  'Hey ${user.displayName}',
                  style: Theme.of(context).textTheme.titleLarge,
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
    return Expanded(
      child: ListView.separated(
        itemCount: tabs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _SideMenuTile(
          tab: tabs[index],
          isSelected: index == selectedIndex,
          onTap: () => onSelected(index),
        ),
      ),
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
        child: Icon(Icons.arrow_left, color: SyscatTheme.iconActive, size: 30),
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
      leading: Icon(tab.icon),
      title: Text(tab.title),
      trailing: isSelected ? const Icon(Icons.check, size: 18) : null,
      onTap: onTap,
    );
  }
}
