import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:go_router/go_router.dart';
import 'core/di/service_locator.dart';
import 'root_tab.dart';
import 'core/widgets/root_app_bar.dart';
import 'core/widgets/root_navigation.dart';
import 'core/widgets/root_shell_scope.dart';
import 'core/widgets/root_side_menu.dart';
import 'core/widgets/syscat_background.dart';
import 'features/assistant/domain/entities/assistant_context.dart';
import 'features/assistant/presentation/widgets/assistant_bell_button.dart';
import 'features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'features/notifications/presentation/widgets/notification_bell_button.dart';
import 'features/notifications/presentation/widgets/notification_side_drawer.dart';
import 'features/task_builder/presentation/widgets/task_builder_shell_frame.dart';
import 'features/knowledge_base/presentation/widgets/knowledge_base_shell_frame.dart';

class RootPage extends StatefulWidget {
  const RootPage({
    super.key,
    required this.location,
    required this.child,
    this.isLocal = false,
  });

  final String location;
  final Widget child;
  final bool isLocal;

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

  @override
  void dispose() {
    _sideMenuController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = rootTabs(isLocal: widget.isLocal);
    final selectedTabIndex = _selectedTabIndex(tabs);
    final selectedTab = tabs[selectedTabIndex];
    final assistantContext = assistantContextForRootTab(
      selectedTab: selectedTab,
      location: widget.location,
      isLocal: widget.isLocal,
    );
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
          leftMenu: RootSideMenu(
            tabs: tabs,
            selectedIndex: selectedTabIndex,
            onSelected: (index) => _selectTab(tabs, index),
            showSessionActions: !widget.isLocal,
          ),
          rightMenu: _isNotificationDrawerOpen
              ? NotificationSideDrawer(onClose: _closeNotificationDrawer)
              : null,
          centerPage: _centerPage(
            selectedTab: selectedTab,
            assistantContext: assistantContext,
            usesTaskBuilderSideRail: usesTaskBuilderSideRail,
            usesKnowledgeBaseSideRail: usesKnowledgeBaseSideRail,
          ),
        ),
      ),
    );
    return RootShellScope(
      controller: _shellController,
      child: widget.isLocal
          ? shell
          : BlocProvider(
              create: (_) => serviceLocator<AppNotificationsCubit>(),
              child: shell,
            ),
    );
  }

  Widget _titleFor(RootTab selectedTab) {
    return _shellController.title ?? Text(selectedTab.title);
  }

  Widget _centerPage({
    required RootTab selectedTab,
    required AssistantContext? assistantContext,
    required bool usesTaskBuilderSideRail,
    required bool usesKnowledgeBaseSideRail,
  }) {
    final title = _titleFor(selectedTab);
    if (usesTaskBuilderSideRail) return _taskBuilderCenterPage(title);
    if (usesKnowledgeBaseSideRail) return _knowledgeBaseCenterPage(title);
    return _defaultCenterPage(title, assistantContext);
  }

  Widget _taskBuilderCenterPage(Widget title) {
    return TaskBuilderShellFrame(
      title: title,
      onMenuPressed: _sideMenuController.openLeftMenu,
      menuWidthOfScreen: _menuWidthOfScreen(context),
      child: widget.child,
    );
  }

  Widget _knowledgeBaseCenterPage(Widget title) {
    return KnowledgeBaseShellFrame(
      title: title,
      onMenuPressed: _sideMenuController.openLeftMenu,
      menuWidthOfScreen: _menuWidthOfScreen(context),
      child: widget.child,
    );
  }

  Widget _defaultCenterPage(Widget title, AssistantContext? assistantContext) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: RootAppBar(
        title: title,
        onMenuPressed: _sideMenuController.openLeftMenu,
        actions: [
          if (assistantContext != null)
            AssistantBellButton(contextInfo: assistantContext),
          if (!widget.isLocal)
            NotificationBellButton(onPressed: _openNotificationDrawer),
        ],
      ),
      body: SafeArea(child: widget.child),
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
