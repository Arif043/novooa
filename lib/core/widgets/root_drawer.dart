import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';
import '../theme/syscat_theme.dart';
import '../../root_tab.dart';

class RootDrawer extends StatelessWidget {
  const RootDrawer({
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
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DrawerHeader(),
              const SizedBox(height: 12),
              _TabList(
                tabs: tabs,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
              ),
              const Spacer(),
              ListTile(
                selected: false,
                iconColor: ColorScheme.of(context).error,
                textColor: ColorScheme.of(context).error,
                leading: const Icon(Icons.logout),
                title: const Text('Abmelden'),
                onTap: () => serviceLocator<AuthCubit>().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          _BrandMark(),
          SizedBox(width: 12),
          FutureBuilder(
            future: serviceLocator<GetCurrentUserProfile>().call(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data case Success(success: final user)) {
                  return Text(
                    'Hey ${user.displayName}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
            blurRadius: 14,
            offset: const Offset(0, 6),
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

class _TabList extends StatelessWidget {
  const _TabList({
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
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) => _DrawerTile(
          tab: tabs[index],
          isSelected: index == selectedIndex,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
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
