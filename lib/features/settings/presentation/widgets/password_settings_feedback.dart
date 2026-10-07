import 'package:flutter/material.dart';

import '../cubits/password_settings_state.dart';

class PasswordSettingsFeedback extends StatelessWidget {
  const PasswordSettingsFeedback({super.key, required this.state});

  final PasswordSettingsState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    PasswordSettingsSaving() => const LinearProgressIndicator(
      semanticsLabel: 'Neues Passwort wird gespeichert',
    ),
    PasswordSettingsFailure(:final failure) => _PasswordFailureFeedback(
      message: failure.message,
    ),
    PasswordSettingsSuccess() => Semantics(
      liveRegion: true,
      child: const Text('Das neue Passwort wurde gespeichert.'),
    ),
    PasswordSettingsReady() => const SizedBox.shrink(),
  };
}

class _PasswordFailureFeedback extends StatelessWidget {
  const _PasswordFailureFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
