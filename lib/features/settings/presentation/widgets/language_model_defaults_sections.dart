import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_state.dart';

import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_field.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_sheet.dart';

import 'settings_section.dart';

/// Vorgabe-Auswahl unter „Sprachmodelle" — welches bereits verbundene Modell
/// als Standardmodell für Sprachmodell-Bausteine ("Standardmodell verwenden")
/// gilt. Blendet sich aus, solange kein Modell verbunden ist — dann gibt es
/// nichts zu wählen. In der lokalen Runtime ([usedByKnowledgeAssistant]) ist
/// es zugleich das Modell des KI-Agenten der Wissensbasis, der dort mit dem
/// Modell des Nutzers läuft.
class LanguageModelDefaultsSections extends StatelessWidget {
  const LanguageModelDefaultsSections({
    super.key,
    this.usedByKnowledgeAssistant = false,
  });

  final bool usedByKnowledgeAssistant;

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
              title: usedByKnowledgeAssistant
                  ? 'Standardmodell'
                  : 'Standardmodell für Sprachmodell-Bausteine',
              description: usedByKnowledgeAssistant
                  ? 'Gilt, wenn ein Baustein "Standardmodell verwenden" nutzt, '
                        'und für den KI-Agenten der Wissensbasis.'
                  : 'Gilt, wenn ein Baustein "Standardmodell verwenden" nutzt.',
              models: state.models,
              selectedModelId: state.defaults.blockModelId,
              isSaving: state.isSavingBlockDefault,
              onChanged: context
                  .read<LanguageModelDefaultsCubit>()
                  .saveBlockDefault,
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
    return SettingsSection(
      icon: icon,
      title: title,
      description: description,
      child: LanguageModelPickerField(
        models: models
            .where((model) => !model.isSpeechModel)
            .toList(growable: false),
        selectedModelId: selectedModelId ?? defaultLanguageModelId,
        enabled: !isSaving,
        defaultOptionLabel: 'Systemvorgabe verwenden',
        onChanged: (modelId) =>
            onChanged(modelId == defaultLanguageModelId ? null : modelId),
      ),
    );
  }
}
