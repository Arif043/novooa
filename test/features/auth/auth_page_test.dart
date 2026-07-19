import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_out.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_form_cubit.dart';
import 'package:syscat2/features/auth/presentation/pages/auth_page.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/ensure_user_profile.dart';

class _AsyncAuthRepository implements AuthRepository {
  final completer = Completer<Result<AuthUser, AuthFailure>>();
  int signInCalls = 0;
  int signUpCalls = 0;

  @override
  AuthUser? currentUser() => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) {
    signInCalls++;
    return completer.future;
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) {
    signUpCalls++;
    return completer.future;
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    return const Result.success(unit);
  }
}

class _FakeUserRepository implements UserRepository {
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

  testWidgets('rendert Register/Login-Segmente', (tester) async {
    await tester.pumpWidget(_appWith(_AsyncAuthRepository()));
    expect(find.text('Registrieren'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
  });

  testWidgets('wechselt in den Login-Modus', (tester) async {
    await tester.pumpWidget(_appWith(_AsyncAuthRepository()));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Name'), findsNothing);
    expect(find.text('Einloggen'), findsOneWidget);
  });

  testWidgets('zeigt Loading und danach Login-Fehler', (tester) async {
    final repository = _AsyncAuthRepository();
    await tester.pumpWidget(_appWith(repository));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'E-Mail'),
      'ada@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'sicheres-passwort',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Einloggen'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.completer.complete(
      const Result.error(AuthFailure(AuthFailureKind.invalidCredentials)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('nicht korrekt'), findsOneWidget);
    expect(repository.signInCalls, 1);
  });
}

Widget _appWith(_AsyncAuthRepository repository) {
  serviceLocator.registerFactory(
    () => AuthFormCubit(
      signUpUseCase: SignUpWithEmailAndPassword(repository),
      signInUseCase: SignInWithEmailAndPassword(repository),
      ensureUserProfileUseCase: EnsureUserProfile(_FakeUserRepository()),
      signOutUseCase: SignOut(repository),
    ),
  );
  return MaterialApp(theme: SyscatTheme.lightTheme, home: const AuthPage());
}
