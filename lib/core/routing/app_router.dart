import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/features/activity/presentation/pages/activity_page.dart';
import 'package:syscat2/features/results/presentation/pages/results_page.dart';
import 'package:syscat2/features/files/presentation/pages/files_page.dart';
import 'package:syscat2/features/data/presentation/pages/database_page.dart';
import 'package:syscat2/features/employees/presentation/pages/employees_page.dart';
import 'package:syscat2/features/knowledge_base/presentation/pages/knowledge_base_page.dart';
import 'package:syscat2/features/schedule/presentation/pages/schedule_page.dart';
import 'package:syscat2/features/settings/presentation/pages/settings_page.dart';
import 'package:syscat2/features/skills/presentation/pages/skills_page.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_builder_page.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_homepage.dart';
import 'package:syscat2/root_page.dart';

class AppRouter {
  static const String home = '/tasks';
  static const String plans = '/plans';
  static const String schedule = '/schedule';
  static const String activity = '/activity';
  static const String results = '/results';
  static const String files = '/files';
  static const String database = '/database';
  static const String knowledgeBase = '/knowledge-base';
  static const String skills = '/skills';
  static const String employees = '/employees';
  static const String settings = '/settings';

  late final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => home),
      ShellRoute(
        builder: (context, state, child) {
          return RootPage(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) =>
                _shellPage(state, const TaskHomepage()),
            routes: [
              GoRoute(
                path: 'builder',
                pageBuilder: (context, state) => _shellPage(
                  state,
                  TaskBuilderPage(
                    editingTaskOrNull: state.extra is Task
                        ? state.extra as Task
                        : null,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: plans,
            pageBuilder: (context, state) => _shellPage(
              state,
              const RootPlaceholderPage(
                title: 'Arbeitspläne',
                content: 'Gespeicherte Aufgaben und Vorlagen erscheinen hier.',
              ),
            ),
          ),
          GoRoute(
            path: schedule,
            pageBuilder: (context, state) =>
                _shellPage(state, const SchedulePage()),
          ),
          GoRoute(
            path: activity,
            pageBuilder: (context, state) => _shellPage(
              state,
              ActivityPage(
                initialRunId: state.uri.queryParameters['runId'],
                notificationOpenId: state.uri.queryParameters['open'],
              ),
            ),
          ),
          GoRoute(
            path: results,
            pageBuilder: (context, state) =>
                _shellPage(state, const ResultsPage()),
          ),
          GoRoute(
            path: files,
            pageBuilder: (context, state) =>
                _shellPage(state, const FilesPage()),
          ),
          GoRoute(
            path: database,
            pageBuilder: (context, state) =>
                _shellPage(state, const DatabasePage()),
          ),
          GoRoute(
            path: knowledgeBase,
            pageBuilder: (context, state) =>
                _shellPage(state, const KnowledgeBasePage()),
          ),
          GoRoute(
            path: skills,
            pageBuilder: (context, state) =>
                _shellPage(state, const SkillsPage()),
          ),
          GoRoute(
            path: employees,
            pageBuilder: (context, state) =>
                _shellPage(state, const EmployeesPage()),
          ),
          GoRoute(
            path: settings,
            pageBuilder: (context, state) =>
                _shellPage(state, const SettingsPage()),
          ),
        ],
      ),
    ],
  );

  void dispose() => router.dispose();

  NoTransitionPage<void> _shellPage(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
}
