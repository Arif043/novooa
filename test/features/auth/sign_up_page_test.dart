import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/pages/sign_up_page.dart';

class _AsyncAuthRepository implements AuthRepository {
  final completer = Completer<Result<AuthUser, AuthFailure>>();

  @override
  AuthUser? currentUser() => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) {
    return completer.future;
  }
}

void main() {
  testWidgets('rendert die SignUp-Page', (tester) async {
    await tester.pumpWidget(_appWith(_AsyncAuthRepository()));
    expect(find.text('Syscat starten'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Passwort'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
  });

  testWidgets('zeigt Loading und danach Fehler-SnackBar', (tester) async {
    final repository = _AsyncAuthRepository();
    await tester.pumpWidget(_appWith(repository));
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Ada');
    await tester.enterText(
      find.widgetWithText(TextField, 'E-Mail'),
      'ada@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'sicheres-passwort',
    );
    await tester.tap(find.text('Konto erstellen'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.completer.complete(
      const Result.error(AuthFailure(AuthFailureKind.emailAlreadyInUse)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('bereits ein Konto'), findsOneWidget);
  });
}

Widget _appWith(_AsyncAuthRepository repository) {
  return MaterialApp(
    theme: SyscatTheme.lightTheme,
    home: SignUpPage(signUp: SignUpWithEmailAndPassword(repository)),
  );
}
