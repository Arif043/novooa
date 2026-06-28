import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/presentation/pages/auth_page.dart';
import 'package:syscat2/features/activity/presentation/pages/activity_page.dart';
import 'package:syscat2/features/settings/presentation/pages/settings_page.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_builder_page.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_homepage.dart';
import 'package:syscat2/root_page.dart';

class AppRouter {
  static const String home = '/tasks';
  static const String auth = '/auth';
  static const String plans = '/plans';
  static const String schedule = '/schedule';
  static const String activity = '/activity';
  static const String settings = '/settings';

  AppRouter({required AuthRepository authRepository})
    : _authRefresh = AuthRefreshNotifier(
        initialUser: authRepository.currentUser(),
        authStateChanges: authRepository.authStateChanges(),
      );

  final AuthRefreshNotifier _authRefresh;

  late final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: _authRefresh,
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
                path: '/builder',
                builder: (context, state) => const TaskBuilderPage(editingTaskOrNull: null,),
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
            builder: (context, state) => const RootPlaceholderPage(
              title: 'Zeitplan',
              content: 'Geplante und wiederkehrende Automationen erscheinen hier.',
            ),
          ),
          GoRoute(path: activity, builder: (context, state) => const ActivityPage()),
          GoRoute(path: settings, builder: (context, state) => const SettingsPage()),
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

  void dispose() => _authRefresh.dispose();

  String? _redirect(BuildContext context, GoRouterState state) {
    final isSignedIn = _authRefresh.currentUser != null;
    final isAuthRoute = state.matchedLocation == auth;
    if (!isSignedIn) return isAuthRoute ? null : auth;
    if (isAuthRoute) return home;
    return null;
  }
}

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier({required AuthUser? initialUser, required Stream<AuthUser?> authStateChanges})
    : _currentUser = initialUser {
    _subscription = authStateChanges.listen(_setUser, onError: (_) {});
  }

  AuthUser? _currentUser;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? get currentUser => _currentUser;

  void _setUser(AuthUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
