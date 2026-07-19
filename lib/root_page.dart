import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:go_router/go_router.dart';
import 'core/di/service_locator.dart';
import 'root_tab.dart';
import 'core/widgets/root_app_bar.dart';
import 'core/widgets/root_shell_scope.dart';
import 'core/widgets/root_side_menu.dart';
import 'core/widgets/syscat_background.dart';
import 'features/assistant/domain/entities/assistant_context.dart';
import 'features/assistant/presentation/widgets/assistant_bell_button.dart';
import 'features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'features/notifications/presentation/widgets/notification_bell_button.dart';
import 'features/task_builder/presentation/widgets/task_builder_shell_frame.dart';

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

  static final List<RootTab> _tabs = [
    RootTab(title: 'Aufgaben', icon: Icons.dashboard_outlined, path: '/tasks'),
    RootTab(title: 'Arbeitspläne', icon: Icons.folder_outlined, path: '/plans'),
    RootTab(
      title: 'Zeitplan',
      icon: Icons.bar_chart_outlined,
      path: '/schedule',
    ),
    RootTab(
      title: 'Aktivitäten',
      icon: Icons.history_outlined,
      path: '/activity',
    ),
    RootTab(
      title: 'Dateien',
      icon: Icons.cloud_upload_outlined,
      path: '/files',
    ),
    RootTab(
      title: 'Wissensbasis',
      icon: Icons.library_books_outlined,
      path: '/knowledge-base',
    ),
    RootTab(
      title: 'Einstellungen',
      icon: Icons.settings_outlined,
      path: '/settings',
    ),
  ];

  void _selectTab(int index) {
    _sideMenuController.closeMenu();
    context.go(_tabs[index].path);
  }

  @override
  void dispose() {
    _sideMenuController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = _selectedTabIndex;
    final selectedTab = _tabs[selectedTabIndex];
    final assistantContext = _assistantContextFor(selectedTab);
    final usesTaskBuilderSideRail = widget.location.startsWith(
      '/tasks/builder',
    );
    return RootShellScope(
      controller: _shellController,
      child: BlocProvider(
        create: (_) => serviceLocator<AppNotificationsCubit>(),
        child: AnimatedBuilder(
          animation: _shellController,
          builder: (context, _) => SyscatBackground(
            child: CupertinoSidemenu(
              controller: _sideMenuController,
              menuWidthOfScreen: _menuWidthOfScreen(context),
              hapticFeedback: false,
              centerBackgroundOpacity: 0.18,
              leftMenu: RootSideMenu(
                tabs: _tabs,
                selectedIndex: selectedTabIndex,
                onSelected: _selectTab,
              ),
              centerPage: _centerPage(
                selectedTab: selectedTab,
                assistantContext: assistantContext,
                usesTaskBuilderSideRail: usesTaskBuilderSideRail,
              ),
            ),
          ),
        ),
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
  }) {
    final title = _titleFor(selectedTab);
    if (usesTaskBuilderSideRail) return _taskBuilderCenterPage(title);
    return _defaultCenterPage(title, assistantContext);
  }

  Widget _taskBuilderCenterPage(Widget title) {
    return TaskBuilderShellFrame(
      title: title,
      onMenuPressed: _sideMenuController.openLeftMenu,
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
          const NotificationBellButton(),
        ],
      ),
      body: SafeArea(child: widget.child),
    );
  }

  AssistantContext? _assistantContextFor(RootTab selectedTab) {
    final area = switch (selectedTab.path) {
      '/tasks' => AssistantArea.taskBuilder,
      '/knowledge-base' => AssistantArea.knowledgeBase,
      _ => null,
    };
    if (area == null) return null;
    return AssistantContext(area: area, route: widget.location);
  }

  double _menuWidthOfScreen(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 0.28;
    if (width >= 800) return 0.42;
    return 0.82;
  }

  int get _selectedTabIndex {
    final index = _tabs.indexWhere(
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
