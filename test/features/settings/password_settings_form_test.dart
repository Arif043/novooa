import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/auth/domain/entities/new_password.dart';
import 'package:syscat2/features/auth/domain/entities/password_failure.dart';
import 'package:syscat2/features/auth/domain/repositories/password_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/set_new_password.dart';
import 'package:syscat2/features/settings/presentation/cubits/password_settings_cubit.dart';
import 'package:syscat2/features/settings/presentation/widgets/password_settings_form.dart';

void main() {
  testWidgets(
    'ein Feld, Klartext-Umschaltung, Ladezustand und leeres Feld nach Erfolg',
    (tester) async {
      final repository = _PasswordRepository();
      await _pumpForm(tester, repository);
      expect(find.byType(TextField), findsOneWidget);
      expect(_field(tester).obscureText, isTrue);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'neues-passwort');
      await tester.tap(find.byTooltip('Passwort anzeigen'));
      await tester.pump();
      expect(_field(tester).obscureText, isFalse);
      await tester.tap(find.text('Passwort speichern'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(_field(tester).enabled, isFalse);
      repository.complete(const Success(unit));
      await tester.pumpAndSettle();
      expect(_field(tester).controller!.text, isEmpty);
      expect(_field(tester).obscureText, isTrue);
      expect(find.text('Das neue Passwort wurde gespeichert.'), findsOneWidget);
    },
  );

  testWidgets('Fehler lässt die Eingabe für einen erneuten Versuch stehen', (
    tester,
  ) async {
    final repository = _PasswordRepository();
    await _pumpForm(tester, repository);
    await tester.enterText(find.byType(TextField), 'neues-passwort');
    await tester.pump();
    await tester.tap(find.text('Passwort speichern'));
    repository.complete(const Error(PasswordFailure.network));
    await tester.pumpAndSettle();
    expect(find.text(PasswordFailure.network.message), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(_field(tester).controller!.text, 'neues-passwort');
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();
    repository.complete(const Success(unit));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('schmale Ansicht mit großer Schrift bleibt ohne Overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpForm(tester, _PasswordRepository(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

Future<void> _pumpForm(
  WidgetTester tester,
  _PasswordRepository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: SyscatTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: BlocProvider(
              create: (_) => PasswordSettingsCubit(SetNewPassword(repository)),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: PasswordSettingsForm(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PasswordRepository implements PasswordRepository {
  Completer<Result<Unit, PasswordFailure>> _completion = Completer();
  int calls = 0;

  void complete(Result<Unit, PasswordFailure> passwordOrFailure) {
    _completion.complete(passwordOrFailure);
    _completion = Completer();
  }

  @override
  Future<Result<Unit, PasswordFailure>> updatePassword(NewPassword password) {
    calls++;
    return _completion.future;
  }
}
