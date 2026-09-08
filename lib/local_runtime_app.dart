import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/syscat_theme.dart';
import 'features/activity/presentation/pages/activity_page.dart';
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
    final taskRoute = location.startsWith('/tasks');
    final isBuilder = location == '/tasks/builder';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBuilder
              ? 'Aufgabe'
              : taskRoute
              ? 'Aufgaben'
              : 'Aktivitäten',
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: taskRoute ? 0 : 1,
        onDestinationSelected: (index) =>
            context.go(index == 0 ? '/tasks' : '/activity'),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            label: 'Aufgaben',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_timeline_outlined),
            label: 'Aktivitäten',
          ),
        ],
      ),
    );
  }
}
