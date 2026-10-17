import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';
import '../cubits/node_language_models_cubit.dart';
import '../cubits/node_language_models_state.dart';
import 'prompt_generation_options_section.dart';

/// Verbindet die Optionen mit dem gewählten Sprachmodell: Das Kontextfenster
/// erscheint nur bei Ollama. Ohne Modellliste (z. B. in der UI-Vorschau)
/// bleibt es ausgeblendet.
class PromptGenerationOptionsForModel extends StatelessWidget {
  const PromptGenerationOptionsForModel({
    super.key,
    required this.options,
    required this.languageModelId,
    required this.onChanged,
  });

  final PromptGenerationOptions options;
  final String languageModelId;
  final ValueChanged<PromptGenerationOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!_hasModelsProvider(context)) return _section(showContextWindow: false);
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) =>
          _section(showContextWindow: _isOllamaModel(state)),
    );
  }

  Widget _section({required bool showContextWindow}) {
    return PromptGenerationOptionsSection(
      options: options,
      showContextWindow: showContextWindow,
      onChanged: onChanged,
    );
  }

  bool _isOllamaModel(NodeLanguageModelsState state) {
    return state.models.any(
      (model) =>
          model.id == languageModelId &&
          model.provider == LanguageModelProvider.ollama,
    );
  }

  bool _hasModelsProvider(BuildContext context) {
    try {
      BlocProvider.of<NodeLanguageModelsCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}
