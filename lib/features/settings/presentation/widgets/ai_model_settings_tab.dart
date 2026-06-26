import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/ai_provider.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import 'settings_section.dart';

class AiModelSettingsTab extends StatelessWidget {
  const AiModelSettingsTab({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final settings = state.aiModelSettings!;
    return SingleChildScrollView(
      child: SettingsSection(
        icon: Icons.auto_awesome,
        title: 'Sprachmodell',
        description: 'Wähle den AI-Provider und speichere deinen API-Key.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<AiProvider>(
              initialValue: state.selectedProvider,
              decoration: const InputDecoration(labelText: 'AI-Provider'),
              items: AiProvider.values
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(provider.label),
                    ),
                  )
                  .toList(),
              onChanged: state.isSavingAiModel
                  ? null
                  : (provider) => _updateProvider(context, provider),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              obscureText: true,
              enabled: !state.isSavingAiModel,
              decoration: InputDecoration(
                labelText: 'API-Key',
                helperText: settings.hasApiKey
                    ? 'Gespeichert: ${settings.maskedApiKey}'
                    : 'Der Key wird gespeichert, aber nicht wieder angezeigt.',
              ),
              onChanged: context.read<SettingsCubit>().updateApiKey,
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: state.isSavingAiModel
                    ? null
                    : context.read<SettingsCubit>().saveAiModelSettings,
                icon: state.isSavingAiModel
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.key_outlined),
                label: const Text('Sprachmodell speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProvider(BuildContext context, AiProvider? provider) {
    if (provider == null) return;
    context.read<SettingsCubit>().updateProvider(provider);
  }
}
