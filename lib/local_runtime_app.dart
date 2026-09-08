import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/syscat_theme.dart';
import 'features/activity/presentation/pages/activity_page.dart';
import 'features/files/presentation/pages/files_page.dart';
import 'features/knowledge_base/presentation/pages/local_knowledge_base_page.dart';
import 'features/schedule/presentation/pages/schedule_page.dart';
import 'features/task_builder/domain/entities/task.dart';
import 'features/task_builder/presentation/pages/local_task_builder_page.dart';
import 'features/task_builder/presentation/pages/task_homepage.dart';

class LocalRuntimeApp extends StatelessWidget {
  const LocalRuntimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'novooa lokal',
      debugShowCheckedModeBanner: false,
      theme: SyscatTheme.lightTheme,
      darkTheme: SyscatTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/tasks',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          _LocalRuntimeShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/tasks',
          builder: (_, _) => const TaskHomepage(),
          routes: [
            GoRoute(
              path: 'builder',
              builder: (_, state) => LocalTaskBuilderPage(
                editingTask: state.extra is Task ? state.extra as Task : null,
              ),
            ),
          ],
        ),
        GoRoute(path: '/activity', builder: (_, _) => const ActivityPage()),
        GoRoute(path: '/schedule', builder: (_, _) => const SchedulePage()),
        GoRoute(path: '/files', builder: (_, _) => const FilesPage()),
        GoRoute(
          path: '/knowledge-base',
          builder: (_, _) => const LocalKnowledgeBasePage(),
        ),
      ],
    ),
  ],
);

class _LocalRuntimeShell extends StatelessWidget {
  const _LocalRuntimeShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final section = _LocalSection.fromLocation(location);
    final isBuilder = location == '/tasks/builder';
    return Scaffold(
      appBar: AppBar(title: Text(isBuilder ? 'Aufgabe' : section.label)),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: section.navigationIndex,
        onDestinationSelected: (index) =>
            context.go(_LocalSection.values[index].route),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            label: 'Aufgaben',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            label: 'Zeitplan',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_timeline_outlined),
            label: 'Aktivitäten',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Dateien',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Wissensbasis',
          ),
        ],
      ),
    );
  }
}

enum _LocalSection {
  tasks('/tasks', 'Aufgaben'),
  schedule('/schedule', 'Zeitplan'),
  activity('/activity', 'Aktivitäten'),
  files('/files', 'Dateien'),
  knowledgeBase('/knowledge-base', 'Wissensbasis');

  const _LocalSection(this.route, this.label);

  final String route;
  final String label;

  int get navigationIndex => _LocalSection.values.indexOf(this);

  static _LocalSection fromLocation(String location) {
    return _LocalSection.values.firstWhere(
      (section) => location.startsWith(section.route),
      orElse: () => _LocalSection.tasks,
    );
  }
}
