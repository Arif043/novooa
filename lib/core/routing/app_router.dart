import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/presentation/pages/auth_page.dart';
import 'package:syscat2/root_page.dart';

class AppRouter {
  static const String home = '/';
  static const String auth = '/auth';

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
      GoRoute(path: home, builder: (context, state) => const RootPage()),
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
  AuthRefreshNotifier({
    required AuthUser? initialUser,
    required Stream<AuthUser?> authStateChanges,
  }) : _currentUser = initialUser {
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
