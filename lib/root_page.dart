import 'package:flutter/material.dart';

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

  static const List<RootTab> _tabs = [
    RootTab(
      title: 'Aufgaben',
      icon: Icons.dashboard_outlined,
      content: 'Übersicht der wichtigsten Kennzahlen.',
    ),
    RootTab(
      title: 'Arbeitspläne',
      icon: Icons.folder_outlined,
      content: 'Verwaltung und Status aller Projekte.',
    ),
    RootTab(
      title: 'Zeitplan',
      icon: Icons.bar_chart_outlined,
      content: 'Analysen, Trends und Auswertungen.',
    ),
    RootTab(
      title: 'Aktivitäten',
      icon: Icons.settings_outlined,
      content: 'Konfiguration von App und Konto.',
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
