import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/logging/syscat_log.dart';
import 'root_tab.dart';
import 'core/widgets/root_app_bar.dart';
import 'core/widgets/root_drawer.dart';
import 'core/widgets/root_stage.dart';
import 'core/widgets/syscat_background.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {

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
      title: 'Einstellungen',
      icon: Icons.settings_outlined,
      path: '/settings',
    ),
  ];

  void _selectTab(int index) {
    context.go(_tabs[index].path);
    Navigator.of(context).pop();
  }

  Future<void> _runTask() async {
    logSyscatInfo(
      'App-Bar Run Task wurde gedrückt, ist aber noch nicht verdrahtet.',
      name: 'syscat.task_builder',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = _selectedTabIndex;
    final selectedTab = _tabs[selectedTabIndex];
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: RootAppBar(title: selectedTab.title, ),
        drawer: RootDrawer(
          tabs: _tabs,
          selectedIndex: selectedTabIndex,
          onSelected: _selectTab,
        ),
        body: RootStage(child: widget.child),
      ),
    );
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
