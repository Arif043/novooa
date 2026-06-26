import 'package:flutter/material.dart';
import 'package:syscat2/features/settings/presentation/pages/settings_page.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_builder_page.dart';

import 'root_tab.dart';
import 'core/widgets/root_app_bar.dart';
import 'core/widgets/root_drawer.dart';
import 'core/widgets/root_stage.dart';
import 'core/widgets/syscat_background.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedTabIndex = 0;

  static final List<RootTab> _tabs = [
    RootTab(
      title: 'Aufgaben',
      icon: Icons.dashboard_outlined,
      builder: (context) => const TaskBuilderPage(),
    ),
    RootTab(
      title: 'Arbeitspläne',
      icon: Icons.folder_outlined,
      builder: (context) => const _PlaceholderPage(
        title: 'Arbeitspläne',
        content: 'Gespeicherte Aufgaben und Vorlagen erscheinen hier.',
      ),
    ),
    RootTab(
      title: 'Zeitplan',
      icon: Icons.bar_chart_outlined,
      builder: (context) => const _PlaceholderPage(
        title: 'Zeitplan',
        content: 'Geplante und wiederkehrende Automationen erscheinen hier.',
      ),
    ),
    RootTab(
      title: 'Aktivitäten',
      icon: Icons.history_outlined,
      builder: (context) => const _PlaceholderPage(
        title: 'Aktivitäten',
        content: 'Runs, Traces und Freigaben erscheinen hier.',
      ),
    ),
    RootTab(
      title: 'Einstellungen',
      icon: Icons.settings_outlined,
      builder: (context) => const SettingsPage(),
    ),
  ];

  void _selectTab(int index) {
    setState(() => _selectedTabIndex = index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = _tabs[_selectedTabIndex];
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: RootAppBar(title: selectedTab.title),
        drawer: RootDrawer(
          tabs: _tabs,
          selectedIndex: _selectedTabIndex,
          onSelected: _selectTab,
        ),
        body: RootStage(tab: selectedTab),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.content});

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
