import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../cubits/password_settings_cubit.dart';
import 'password_settings_form.dart';
import 'settings_section.dart';

class PasswordSettingsSection extends StatelessWidget {
  const PasswordSettingsSection({super.key, this.isStandalone = false});

  final bool isStandalone;

  @override
  Widget build(BuildContext context) => SettingsSection(
    icon: Icons.lock_outline,
    title: 'Passwort neu setzen',
    description: isStandalone
        ? 'Lege ein neues Zugriffs-Passwort für diese Installation fest. Alle Geräte verwenden es bei der nächsten Anmeldung.'
        : 'Lege ein neues Passwort für dein Konto fest.',
    child: BlocProvider(
      create: (_) => serviceLocator<PasswordSettingsCubit>(),
      child: const PasswordSettingsForm(),
    ),
  );
}
