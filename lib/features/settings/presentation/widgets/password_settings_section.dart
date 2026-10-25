import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';

import '../../../../core/di/service_locator.dart';
import '../cubits/password_settings_cubit.dart';
import 'password_settings_form.dart';
import 'settings_section.dart';

class PasswordSettingsSection extends StatelessWidget {
  const PasswordSettingsSection({super.key});

  @override
  Widget build(BuildContext context) => SettingsSection(
    icon: Icons.lock_outline,
    title: 'Passwort neu setzen',
    description: LocaleKeys.runtime_users_own_password_description.tr(),
    child: BlocProvider(
      create: (_) => serviceLocator<PasswordSettingsCubit>(),
      child: const PasswordSettingsForm(),
    ),
  );
}
