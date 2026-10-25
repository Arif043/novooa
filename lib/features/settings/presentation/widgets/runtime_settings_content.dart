import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_state.dart';
import 'package:syscat2/features/runtime_sessions/presentation/cubits/runtime_sessions_cubit.dart';
import 'package:syscat2/features/runtime_sessions/presentation/widgets/runtime_sessions_section.dart';
import 'package:syscat2/features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import 'package:syscat2/features/runtime_users/presentation/widgets/runtime_users_settings_tab.dart';

import 'package:syscat2/features/communication/presentation/widgets/communication_settings_tab.dart';

import 'package:syscat2/core/localization/locale_keys.g.dart';

import 'adaptive_settings_tabs.dart';
import 'file_version_limit_section.dart';
import 'language_settings_section.dart';
import 'settings_tab_contribution.dart';
import 'password_settings_section.dart';
import 'settings_section.dart';
import 'ai_model_settings_tab.dart';
import 'runtime_license_status.dart';
import '../../../machine_learning/presentation/widgets/machine_learning_settings_tab.dart';
import '../../../connections/presentation/widgets/connections_settings_tab.dart';
import '../../../workspace_transfer/presentation/widgets/import_export_settings_tab.dart';

/// Die Reiter der Runtime-Einstellungen. Mitglieder sehen nur, was ihr
/// eigenes Konto betrifft; Benutzer, Lizenz und Anbindungen verwalten Admins.
List<SettingsTabContribution> runtimeSettingsTabs({required bool isAdmin}) => [
  SettingsTabContribution(
    icon: Icons.settings_outlined,
    labelKey: LocaleKeys.settings_tabs_general,
    builder: (_) => _GeneralTab(isAdmin: isAdmin),
  ),
  if (isAdmin) ...[
    SettingsTabContribution(
      icon: Icons.group_outlined,
      labelKey: LocaleKeys.settings_tabs_users,
      builder: (_) => const RuntimeUsersSettingsTab(),
    ),
    SettingsTabContribution(
      icon: Icons.auto_awesome,
      labelKey: LocaleKeys.settings_tabs_language_models,
      builder: (_) => const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AiModelSettingsTab(scrollable: false),
      ),
    ),
    SettingsTabContribution(
      icon: CupertinoIcons.chat_bubble_2,
      labelKey: LocaleKeys.settings_tabs_communication,
      builder: (_) => const CommunicationSettingsTab(),
    ),
    SettingsTabContribution(
      icon: Icons.link,
      labelKey: LocaleKeys.settings_tabs_connections,
      builder: (_) => const ConnectionsSettingsTab(),
    ),
  ],
  SettingsTabContribution(
    icon: Icons.memory_outlined,
    labelKey: LocaleKeys.settings_tabs_machine_learning,
    builder: (_) => const MachineLearningSettingsTab(),
  ),
  if (isAdmin)
    SettingsTabContribution(
      icon: Icons.import_export,
      labelKey: LocaleKeys.settings_tabs_import_export,
      builder: (_) => const ImportExportSettingsTab(),
    ),
];

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const LanguageSettingsSection(),
        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),
          const _RuntimeSection(),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _SessionsSection(),
        const SizedBox(height: AppSpacing.lg),
        const PasswordSettingsSection(),
        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),
          const FileVersionLimitSection(),
        ],
      ],
    );
  }
}

class RuntimeSettingsContent extends StatelessWidget {
  const RuntimeSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select(
      (CurrentRuntimeUserCubit cubit) => cubit.state.isAdmin,
    );
    return AdaptiveSettingsTabs(
      key: ValueKey(isAdmin),
      tabs: runtimeSettingsTabs(isAdmin: isAdmin),
    );
  }
}

class _RuntimeSection extends StatelessWidget {
  const _RuntimeSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.dns_outlined,
      title: 'Runtime',
      description: 'Status und Lizenz dieser novooa-Installation.',
      child: BlocBuilder<RuntimeLicenseCubit, RuntimeLicenseCubitState>(
        builder: (context, state) => switch (state) {
          RuntimeLicenseLoading() ||
          RuntimeLicenseActivating() ||
          RuntimeLicenseReleasing() => const LinearProgressIndicator(),
          RuntimeLicenseActive(:final status) => RuntimeLicenseStatusContent(
            status: status,
          ),
          RuntimeLicenseNeedsActivation() || RuntimeLicenseFailureState() =>
            const Text('Die Runtime ist nicht aktiviert.'),
        },
      ),
    );
  }
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.devices_outlined,
      title: 'Angemeldete Geräte',
      description:
          'Geräte bleiben angemeldet, solange sie mindestens einmal pro Woche genutzt werden.',
      child: BlocProvider(
        create: (_) => serviceLocator<RuntimeSessionsCubit>(),
        child: const RuntimeSessionsSection(),
      ),
    );
  }
}
