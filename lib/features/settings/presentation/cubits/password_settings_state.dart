import '../../../auth/domain/entities/password_failure.dart';

sealed class PasswordSettingsState {
  const PasswordSettingsState();
}

class PasswordSettingsReady extends PasswordSettingsState {
  const PasswordSettingsReady();
}

class PasswordSettingsSaving extends PasswordSettingsState {
  const PasswordSettingsSaving();
}

class PasswordSettingsSuccess extends PasswordSettingsState {
  const PasswordSettingsSuccess();
}

class PasswordSettingsFailure extends PasswordSettingsState {
  const PasswordSettingsFailure(this.failure);

  final PasswordFailure failure;
}
