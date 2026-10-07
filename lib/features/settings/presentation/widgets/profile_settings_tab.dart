import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../../user/domain/entities/user_profile.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import 'settings_section.dart';
import 'password_settings_section.dart';

class ProfileSettingsTab extends StatelessWidget {
  const ProfileSettingsTab({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSection(state: state, profile: state.profile!),
          const SizedBox(height: AppSpacing.lg),
          const PasswordSettingsSection(),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.state, required this.profile});

  final SettingsState state;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.person_outline,
      title: 'Profil',
      description: 'Verwalte deinen Anzeigenamen und deine Kontoangaben.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: ValueKey(profile.id.value),
            initialValue: state.displayNameInput,
            enabled: !state.isSavingProfile,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: context.read<SettingsCubit>().updateDisplayName,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: profile.email.value,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'E-Mail'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: profile.id.value,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Nutzer-ID'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: state.isSavingProfile
                  ? null
                  : context.read<SettingsCubit>().saveProfile,
              icon: state.isSavingProfile
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Profil speichern'),
            ),
          ),
        ],
      ),
    );
  }
}
