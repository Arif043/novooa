import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/settings/presentation/widgets/settings_section.dart';

import '../../domain/entities/plugin_manifest.dart';
import '../../domain/usecases/plugin_use_cases.dart';
import '../cubits/plugin_settings_cubit.dart';
import '../cubits/plugin_settings_state.dart';
import 'plugin_field_editor.dart';
import 'plugin_icons.dart';

/// Die Einstellungs-Panels eines Plugins, deklarativ aus dem Manifest gerendert.
class PluginSettingsPanels extends StatelessWidget {
  const PluginSettingsPanels({super.key, required this.manifest});

  final PluginManifest manifest;

  @override
  Widget build(BuildContext context) {
    if (manifest.settingsPanels.isEmpty) return const SizedBox.shrink();
    return BlocProvider(
      // Neu laden, wenn eine andere Version installiert wird.
      key: ValueKey('${manifest.id}@${manifest.version}'),
      create: (_) => PluginSettingsCubit(
        manifest.id,
        serviceLocator<LoadPluginSettings>(),
        serviceLocator<SavePluginSettings>(),
      )..load(),
      child: BlocConsumer<PluginSettingsCubit, PluginSettingsState>(
        listenWhen: (previous, current) =>
            current.message != null && current.message != previous.message,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
          context.read<PluginSettingsCubit>().messageShown();
        },
        builder: (context, state) => switch (state.status) {
          PluginSettingsStatus.loading => const LinearProgressIndicator(),
          PluginSettingsStatus.failure => Text(
            state.message ?? 'Einstellungen konnten nicht geladen werden.',
          ),
          PluginSettingsStatus.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final panel in manifest.settingsPanels) ...[
                _Panel(panel: panel, state: state),
                const SizedBox(height: AppSpacing.md),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: state.hasChanges && !state.saving
                      ? context.read<PluginSettingsCubit>().save
                      : null,
                  child: Text(state.saving ? 'Speichert …' : 'Speichern'),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.panel, required this.state});

  final PluginSettingsPanel panel;
  final PluginSettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PluginSettingsCubit>();
    return SettingsSection(
      icon: pluginIconFor(panel.icon),
      title: panel.title,
      description: panel.description ?? '',
      child: Column(
        children: [
          for (final field in panel.fields)
            PluginFieldEditor(
              key: ValueKey('${panel.id}.${field.key}'),
              field: field,
              value: field.secret ? null : state.valueOf(field.key),
              secretIsSet: state.settings.secretsSet.contains(field.key),
              onChanged: (value) => cubit.setValue(field.key, value),
            ),
        ],
      ),
    );
  }
}
