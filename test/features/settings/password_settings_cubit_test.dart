import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/auth/domain/entities/new_password.dart';
import 'package:syscat2/features/auth/domain/entities/password_failure.dart';
import 'package:syscat2/features/auth/domain/repositories/password_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/set_new_password.dart';
import 'package:syscat2/features/settings/presentation/cubits/password_settings_cubit.dart';
import 'package:syscat2/features/settings/presentation/cubits/password_settings_state.dart';

void main() {
  test('speichert ausschließlich das neue Passwort unverändert', () async {
    final repository = _PasswordRepository();
    final cubit = PasswordSettingsCubit(SetNewPassword(repository));
    addTearDown(cubit.close);
    await cubit.save('  neu & sicher  ');
    expect(repository.passwords, ['  neu & sicher  ']);
    expect(cubit.state, isA<PasswordSettingsSuccess>());
  });

  test(
    'leere, zu kurze und zu lange Passwörter erreichen den Adapter nicht',
    () async {
      final repository = _PasswordRepository();
      final cubit = PasswordSettingsCubit(SetNewPassword(repository));
      addTearDown(cubit.close);
      for (final password in ['', 'kurz', 'x' * 1001]) {
        await cubit.save(password);
        expect(
          (cubit.state as PasswordSettingsFailure).failure,
          PasswordFailure.invalidPassword,
        );
      }
      expect(repository.passwords, isEmpty);
    },
  );

  test('zeigt Backendfehler und erlaubt einen erneuten Versuch', () async {
    final repository = _PasswordRepository()
      ..failure = PasswordFailure.recentLoginRequired;
    final cubit = PasswordSettingsCubit(SetNewPassword(repository));
    addTearDown(cubit.close);
    await cubit.save('neues-passwort');
    expect(
      (cubit.state as PasswordSettingsFailure).failure,
      PasswordFailure.recentLoginRequired,
    );
    repository.failure = null;
    await cubit.save('neues-passwort');
    expect(cubit.state, isA<PasswordSettingsSuccess>());
  });

  test(
    'verhindert paralleles Speichern und ignoriert Abschluss nach dispose',
    () async {
      final completion = Completer<Result<Unit, PasswordFailure>>();
      final repository = _PasswordRepository()..pending = completion.future;
      final cubit = PasswordSettingsCubit(SetNewPassword(repository));
      final saving = cubit.save('neues-passwort');
      expect(cubit.state, isA<PasswordSettingsSaving>());
      await cubit.save('zweites-passwort');
      expect(repository.passwords, ['neues-passwort']);
      await cubit.close();
      completion.complete(const Success(unit));
      await saving;
    },
  );
}

class _PasswordRepository implements PasswordRepository {
  final passwords = <String>[];
  PasswordFailure? failure;
  Future<Result<Unit, PasswordFailure>>? pending;

  @override
  Future<Result<Unit, PasswordFailure>> updatePassword(
    NewPassword password,
  ) async {
    passwords.add(password.value);
    return pending ?? (failure == null ? const Success(unit) : Error(failure!));
  }
}
