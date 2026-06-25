import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/domain/unique_id.dart';
import 'package:syscat2/core/routing/app_router.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/ensure_user_profile.dart';

class _RouterAuthRepository implements AuthRepository {
  _RouterAuthRepository(this._currentUser);

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? currentUser() => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    _currentUser = _buildUser(email.value, '');
    _controller.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    _currentUser = _buildUser(email.value, name);
    _controller.add(_currentUser);
    return Result.success(_currentUser!);
  }

  AuthUser _buildUser(String email, String displayName) {
    return AuthUser(
      id: const UniqueId('user.1'),
      email: email,
      displayName: displayName,
    );
  }

  Future<void> close() => _controller.close();
}

class _RouterUserRepository implements UserRepository {
  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    return Result.success(
      UserProfile(
        id: id,
        email: email,
        displayName: displayName,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    return const Result.error(UserFailure(UserFailureKind.notFound));
  }
}

void main() {
  tearDown(() async => serviceLocator.reset());

  testWidgets('leitet unauthentifizierte Nutzer zur Auth-Route', (
    tester,
  ) async {
    final repository = _RouterAuthRepository(null);
    final userRepository = _RouterUserRepository();
    _registerAuthCubit(repository, userRepository);
    final appRouter = AppRouter(authRepository: repository);
    await tester.pumpWidget(_appWith(appRouter));
    await tester.pumpAndSettle();
    expect(find.text('Syscat starten'), findsOneWidget);
    appRouter.dispose();
    await repository.close();
  });

  testWidgets('zeigt RootPage fuer authentifizierte Nutzer', (tester) async {
    final repository = _RouterAuthRepository(
      const AuthUser(
        id: UniqueId('user.1'),
        email: 'ada@example.com',
        displayName: 'Ada',
      ),
    );
    final userRepository = _RouterUserRepository();
    _registerAuthCubit(repository, userRepository);
    final appRouter = AppRouter(authRepository: repository);
    await tester.pumpWidget(_appWith(appRouter));
    await tester.pumpAndSettle();
    expect(find.text('Aufgaben'), findsOneWidget);
    appRouter.dispose();
    await repository.close();
  });
}

void _registerAuthCubit(
  AuthRepository authRepository,
  UserRepository userRepository,
) {
  serviceLocator.registerFactory(
    () => AuthCubit(
      signUp: SignUpWithEmailAndPassword(authRepository),
      signIn: SignInWithEmailAndPassword(authRepository),
      ensureUserProfile: EnsureUserProfile(userRepository),
    ),
  );
}

Widget _appWith(AppRouter appRouter) {
  return MaterialApp.router(
    theme: SyscatTheme.lightTheme,
    routerConfig: appRouter.router,
  );
}
