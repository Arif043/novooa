import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/password_settings_state.dart';

class PasswordSettingsSaveButton extends StatelessWidget {
  const PasswordSettingsSaveButton({
    super.key,
    required this.state,
    required this.hasInput,
    required this.onSave,
  });

  final PasswordSettingsState state;
  final bool hasInput;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
      ),
      onPressed: state is PasswordSettingsSaving || !hasInput ? null : onSave,
      icon: const Icon(Icons.lock_reset_outlined),
      label: Text(switch (state) {
        PasswordSettingsSaving() => 'Passwort wird gespeichert …',
        PasswordSettingsFailure() => 'Erneut versuchen',
        _ => 'Passwort speichern',
      }),
    ),
  );
}
