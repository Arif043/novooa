import 'package:bloc/bloc.dart';

import '../../../auth/domain/entities/password_failure.dart';
import '../../../auth/domain/usecases/set_new_password.dart';
import 'password_settings_state.dart';

class PasswordSettingsCubit extends Cubit<PasswordSettingsState> {
  PasswordSettingsCubit(this._setNewPassword)
    : super(const PasswordSettingsReady());

  final SetNewPassword _setNewPassword;

  void clearFeedback() {
    if (state is! PasswordSettingsSaving) emit(const PasswordSettingsReady());
  }

  Future<void> save(String password) async {
    if (state is PasswordSettingsSaving) return;
    emit(const PasswordSettingsSaving());
    try {
      final passwordOrFailure = await _setNewPassword(password);
      if (isClosed) return;
      passwordOrFailure.when(
        (_) => emit(const PasswordSettingsSuccess()),
        (failure) => emit(PasswordSettingsFailure(failure)),
      );
    } on Object {
      if (!isClosed) {
        emit(const PasswordSettingsFailure(PasswordFailure.unexpected));
      }
    }
  }
}
