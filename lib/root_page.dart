import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:go_router/go_router.dart';
import 'core/di/service_locator.dart';
import 'core/runtime/runtime_connection_cubit.dart';
import 'root_tab.dart';
import 'features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import 'core/widgets/root_center_page.dart';
import 'core/widgets/root_navigation.dart';
import 'core/widgets/root_shell_scope.dart';
import 'core/widgets/root_side_menu.dart';
import 'core/widgets/syscat_background.dart';
import 'features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'features/notifications/presentation/widgets/notification_side_drawer.dart';
import 'features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'features/licensing/presentation/cubits/runtime_license_state.dart';
import 'features/licensing/presentation/pages/runtime_activation_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final RootShellController _shellController = RootShellController();
  final CupertinoSidemenuController _sideMenuController =
      CupertinoSidemenuController();
  bool _isNotificationDrawerOpen = false;

  void _selectTab(List<RootTab> tabs, int index) {
    _sideMenuController.closeMenu();
    context.go(tabs[index].path);
  }

  Widget _sideMenu(
    BuildContext context,
    List<RootTab> tabs,
    int selectedTabIndex,
  ) {
    return BlocBuilder<CurrentRuntimeUserCubit, CurrentRuntimeUserState>(
      builder: (context, state) => RootSideMenu(
        tabs: tabs,
        selectedIndex: selectedTabIndex,
        onSelected: (index) => _selectTab(tabs, index),
        currentUserName: _greetingName(state),
        onSignOut: () => context.read<RuntimeConnectionCubit>().signOut(),
      ),
    );
  }

  String? _greetingName(CurrentRuntimeUserState state) {
    return switch (state) {
      CurrentRuntimeUserLoaded(:final user) =>
        user.displayName.trim().isEmpty ? user.loginName : user.displayName,
      CurrentRuntimeUserLoading() || CurrentRuntimeUserUnavailable() => null,
    };
  }

  @override
  void dispose() {
    _sideMenuController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RuntimeLicenseCubit, RuntimeLicenseCubitState>(
      builder: (context, state) {
        if (state is RuntimeLicenseActive) return _shell(widget.child);
        return const RuntimeActivationPage();
      },
    );
  }

  Widget _shell(Widget content) {
    final tabs = rootTabs();
    final selectedTabIndex = _selectedTabIndex(tabs);
    final selectedTab = tabs[selectedTabIndex];
    final usesTaskBuilderSideRail = widget.location.startsWith(
      '/tasks/builder',
    );
    final usesKnowledgeBaseSideRail = widget.location.startsWith(
      '/knowledge-base',
    );
    final shell = AnimatedBuilder(
      animation: _shellController,
      builder: (context, _) => SyscatBackground(
        child: CupertinoSidemenu(
          controller: _sideMenuController,
          menuWidthOfScreen: _menuWidthOfScreen(context),
          hapticFeedback: false,
          centerBackgroundOpacity: 0.18,
          leftMenu: _sideMenu(context, tabs, selectedTabIndex),
          rightMenu: _isNotificationDrawerOpen
              ? NotificationSideDrawer(onClose: _closeNotificationDrawer)
              : null,
          centerPage: RootCenterPage(
            usesTaskBuilderSideRail: usesTaskBuilderSideRail,
            usesKnowledgeBaseSideRail: usesKnowledgeBaseSideRail,
            content: content,
            title: _shellController.title ?? Text(selectedTab.title),
            onMenuPressed: _sideMenuController.openLeftMenu,
            menuWidthOfScreen: _menuWidthOfScreen(context),
            onNotificationPressed: _openNotificationDrawer,
          ),
        ),
      ),
    );
    return RootShellScope(
      controller: _shellController,
      child: BlocProvider(
        create: (_) => serviceLocator<AppNotificationsCubit>(),
        child: shell,
      ),
    );
  }

  double _menuWidthOfScreen(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 0.28;
    if (width >= 800) return 0.42;
    return 0.82;
  }

  void _openNotificationDrawer() {
    setState(() => _isNotificationDrawerOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sideMenuController.openRightMenu();
    });
  }

  void _closeNotificationDrawer() {
    _sideMenuController.closeMenu();
    setState(() => _isNotificationDrawerOpen = false);
  }

  int _selectedTabIndex(List<RootTab> tabs) {
    final index = tabs.indexWhere(
      (tab) => widget.location.startsWith(tab.path),
    );
    return index == -1 ? 0 : index;
  }
}

class RootPlaceholderPage extends StatelessWidget {
  const RootPlaceholderPage({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 10),
          Text(content, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
