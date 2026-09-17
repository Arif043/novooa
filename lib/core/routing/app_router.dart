import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/config/mvp_feature_flags.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_state.dart';
import 'package:syscat2/features/auth/presentation/pages/auth_page.dart';
import 'package:syscat2/features/activity/presentation/pages/activity_page.dart';
import 'package:syscat2/features/notifications/infrastructure/datasources/push_click_navigation_policy.dart';
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
  static const String auth = '/auth';
  static const String plans = '/plans';
  static const String schedule = '/schedule';
  static const String activity = '/activity';
  static const String files = '/files';
  static const String database = '/database';
  static const String knowledgeBase = '/knowledge-base';
  static const String skills = '/skills';
  static const String employees = '/employees';
  static const String settings = '/settings';

  AppRouter({required this.sessionCubit, this.isStandalone = false});

  AppRouter.standalone() : sessionCubit = null, isStandalone = true;

  final AuthSessionCubit? sessionCubit;
  final bool isStandalone;

  late final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: sessionCubit,
    redirect: _redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => home),
      ShellRoute(
        builder: (context, state, child) {
          return RootPage(
            location: state.uri.path,
            isStandalone: isStandalone,
            child: child,
          );
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
                isStandalone: isStandalone,
              ),
            ),
          ),
          GoRoute(
            path: files,
            pageBuilder: (context, state) =>
                _shellPage(state, const FilesPage()),
          ),
          GoRoute(
            path: database,
            redirect: (context, state) => isStandalone ? null : home,
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
            redirect: (context, state) =>
                MvpFeatureFlags.skillsEnabled ? null : home,
            pageBuilder: (context, state) =>
                _shellPage(state, const SkillsPage()),
          ),
          GoRoute(
            path: employees,
            redirect: (context, state) =>
                MvpFeatureFlags.employeesEnabled ? null : home,
            pageBuilder: (context, state) =>
                _shellPage(state, const EmployeesPage()),
          ),
          GoRoute(
            path: settings,
            pageBuilder: (context, state) =>
                _shellPage(state, SettingsPage(isStandalone: isStandalone)),
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

  NoTransitionPage<void> _shellPage(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    if (sessionCubit == null) {
      return state.matchedLocation == auth ? home : null;
    }
    final sessionState = sessionCubit!.state;
    final isAuthRoute = state.matchedLocation == auth;
    // Während der Firestore-Profil-Verify läuft, ist `currentUser` bewusst
    // noch nicht sichtbar. Wir halten den Nutzer auf der aktuellen Route
    // fest — wechselt der Verify auf Erfolg, feuert der Listener und wir
    // routen dann zu `home`.
    if (sessionState.status == AuthSessionStatus.verifying) return null;
    final isSignedIn = sessionState.isSignedIn;
    if (!isSignedIn) return isAuthRoute ? null : auth;
    if (isAuthRoute) return home;
    if (_isLegacyDesktopPushLink(state)) return home;
    return null;
  }

  bool _isLegacyDesktopPushLink(GoRouterState state) {
    return !shouldNavigateFromPushClick() &&
        state.matchedLocation == activity &&
        state.uri.queryParameters.containsKey('runId') &&
        !state.uri.queryParameters.containsKey('open');
  }
}
