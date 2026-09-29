import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_state.dart';

import 'settings_section.dart';

/// Zwei Vorgabe-Auswahlen unter „Sprachmodelle" — welches bereits
/// verbundene Modell als Standardmodell für Sprachmodell-Bausteine
/// ("Standardmodell verwenden") bzw. für den KI-Agenten gilt. Blendet sich
/// aus, solange kein Modell verbunden ist — dann gibt es nichts zu wählen.
class LanguageModelDefaultsSections extends StatelessWidget {
  const LanguageModelDefaultsSections({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageModelDefaultsCubit, LanguageModelDefaultsState>(
      builder: (context, state) {
        if (state.models.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _LanguageModelDefaultSection(
              icon: Icons.smart_toy_outlined,
              title: 'Standardmodell für Sprachmodell-Bausteine',
              description:
                  'Gilt, wenn ein Baustein "Standardmodell verwenden" nutzt.',
              models: state.models,
              selectedModelId: state.defaults.blockModelId,
              isSaving: state.isSavingBlockDefault,
              onChanged: context.read<LanguageModelDefaultsCubit>().saveBlockDefault,
            ),
            const SizedBox(height: AppSpacing.lg),
            _LanguageModelDefaultSection(
              icon: Icons.auto_awesome,
              title: 'Sprachmodell des KI-Agenten',
              description: 'Gilt für Fragen an den KI-Agenten in diesem Team.',
              models: state.models,
              selectedModelId: state.defaults.assistantModelId,
              isSaving: state.isSavingAssistantDefault,
              onChanged:
                  context.read<LanguageModelDefaultsCubit>().saveAssistantDefault,
            ),
          ],
        );
      },
    );
  }
}

class _LanguageModelDefaultSection extends StatelessWidget {
  const _LanguageModelDefaultSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.models,
    required this.selectedModelId,
    required this.isSaving,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<LanguageModel> models;
  final String? selectedModelId;
  final bool isSaving;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = models.any((model) => model.id == selectedModelId)
        ? selectedModelId
        : null;
    return SettingsSection(
      icon: icon,
      title: title,
      description: description,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Sprachmodell'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Systemvorgabe verwenden')),
          for (final model in models)
            DropdownMenuItem(value: model.id, child: Text(model.name)),
        ],
        onChanged: isSaving ? null : onChanged,
      ),
    );
  }
}
