import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/pages/sign_up_page.dart';
import 'package:syscat2/root_page.dart';

class AppRouter {
  static const String home = '/';
  static const String signUp = '/signup';

  AppRouter({required AuthRepository authRepository})
    : _authRepository = authRepository,
      _authRefresh = AuthRefreshNotifier(
        initialUser: authRepository.currentUser(),
        authStateChanges: authRepository.authStateChanges(),
      );

  final AuthRepository _authRepository;
  final AuthRefreshNotifier _authRefresh;

  late final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: _authRefresh,
    redirect: _redirect,
    routes: [
      GoRoute(path: home, builder: (context, state) => const RootPage()),
      GoRoute(
        path: signUp,
        builder: (context, state) {
          return SignUpPage(
            signUp: SignUpWithEmailAndPassword(_authRepository),
          );
        },
      ),
    ],
  );

  void dispose() => _authRefresh.dispose();

  String? _redirect(BuildContext context, GoRouterState state) {
    final isSignedIn = _authRefresh.currentUser != null;
    final isSigningUp = state.matchedLocation == signUp;
    if (!isSignedIn) return isSigningUp ? null : signUp;
    if (isSigningUp) return home;
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
