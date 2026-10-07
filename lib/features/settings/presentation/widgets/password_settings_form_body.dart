import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/password_settings_state.dart';
import 'new_password_field.dart';
import 'password_settings_save_button.dart';
import 'password_settings_feedback.dart';

class PasswordSettingsFormBody extends StatelessWidget {
  const PasswordSettingsFormBody({
    super.key,
    required this.state,
    required this.passwordField,
    required this.hasInput,
    required this.onSave,
  });

  final PasswordSettingsState state;
  final NewPasswordField passwordField;
  final bool hasInput;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      passwordField,
      const SizedBox(height: AppSpacing.md),
      PasswordSettingsFeedback(state: state),
      const SizedBox(height: AppSpacing.md),
      PasswordSettingsSaveButton(
        state: state,
        hasInput: hasInput,
        onSave: onSave,
      ),
    ],
  );
}
