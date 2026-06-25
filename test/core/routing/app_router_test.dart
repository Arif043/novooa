import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/routing/app_router.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/entities/unique_id.dart';

class _RouterAuthRepository implements AuthRepository {
  _RouterAuthRepository(this._currentUser);

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? currentUser() => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    _currentUser = AuthUser(
      id: const UniqueId('user.1'),
      email: email.value,
      displayName: name,
    );
    _controller.add(_currentUser);
    return Result.success(_currentUser!);
  }

  Future<void> close() => _controller.close();
}

void main() {
  testWidgets('leitet unauthentifizierte Nutzer zur SignUp-Route', (
    tester,
  ) async {
    final repository = _RouterAuthRepository(null);
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
    final appRouter = AppRouter(authRepository: repository);
    await tester.pumpWidget(_appWith(appRouter));
    await tester.pumpAndSettle();
    expect(find.text('Aufgaben'), findsOneWidget);
    appRouter.dispose();
    await repository.close();
  });
}

Widget _appWith(AppRouter appRouter) {
  return MaterialApp.router(
    theme: SyscatTheme.lightTheme,
    routerConfig: appRouter.router,
  );
}
