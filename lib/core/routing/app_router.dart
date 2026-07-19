import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_state.dart';
import 'package:syscat2/features/auth/presentation/pages/auth_page.dart';
import 'package:syscat2/features/activity/presentation/pages/activity_page.dart';
import 'package:syscat2/features/files/presentation/pages/files_page.dart';
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
  static const String auth = '/auth';
  static const String plans = '/plans';
  static const String schedule = '/schedule';
  static const String activity = '/activity';
  static const String files = '/files';
  static const String knowledgeBase = '/knowledge-base';
  static const String skills = '/skills';
  static const String employees = '/employees';
  static const String settings = '/settings';

  AppRouter({required this.sessionCubit});

  final AuthSessionCubit sessionCubit;

  late final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: sessionCubit,
    redirect: _redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => home),
      ShellRoute(
        builder: (context, state, child) {
          return RootPage(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const TaskHomepage(),
            routes: [
              GoRoute(
                path: 'builder',
                builder: (context, state) => TaskBuilderPage(
                  editingTaskOrNull: state.extra is Task
                      ? state.extra as Task
                      : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: plans,
            builder: (context, state) => const RootPlaceholderPage(
              title: 'Arbeitspläne',
              content: 'Gespeicherte Aufgaben und Vorlagen erscheinen hier.',
            ),
          ),
          GoRoute(
            path: schedule,
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: activity,
            builder: (context, state) => const ActivityPage(),
          ),
          GoRoute(path: files, builder: (context, state) => const FilesPage()),
          GoRoute(
            path: knowledgeBase,
            builder: (context, state) => const KnowledgeBasePage(),
          ),
          GoRoute(
            path: skills,
            builder: (context, state) => const SkillsPage(),
          ),
          GoRoute(
            path: employees,
            builder: (context, state) => const EmployeesPage(),
          ),
          GoRoute(
            path: settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: auth,
        builder: (context, state) {
          return const AuthPage();
        },
      ),
    ],
  );

  void dispose() => router.dispose();

  String? _redirect(BuildContext context, GoRouterState state) {
    final sessionState = sessionCubit.state;
    final isAuthRoute = state.matchedLocation == auth;
    // Während der Firestore-Profil-Verify läuft, ist `currentUser` bewusst
    // noch nicht sichtbar. Wir halten den Nutzer auf der aktuellen Route
    // fest — wechselt der Verify auf Erfolg, feuert der Listener und wir
    // routen dann zu `home`.
    if (sessionState.status == AuthSessionStatus.verifying) return null;
    final isSignedIn = sessionState.isSignedIn;
    if (!isSignedIn) return isAuthRoute ? null : auth;
    if (isAuthRoute) return home;
    return null;
  }
}
