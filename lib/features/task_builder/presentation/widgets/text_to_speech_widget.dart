import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_field.dart';
import 'package:syscat2/features/speech_synthesis/presentation/cubits/speech_voices_cubit.dart';
import 'package:syscat2/features/speech_synthesis/presentation/widgets/speech_voice_field.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/node_language_models_cubit.dart';
import '../cubits/node_language_models_state.dart';
import '../cubits/task_builder_cubit.dart';
import 'model_inference_widget.dart';
import 'speech_text_mapping_field.dart';

/// „Text vorlesen": entweder über ein verbundenes Sprachmodell (Google AI,
/// ElevenLabs, OpenAI-kompatibel) oder über ein lokales ONNX-Modell. Die
/// Auswahl der Sprachmodelle ist bewusst nicht gefiltert — welche Modelle
/// sprechen können, entscheidet der Anbieter.
class TextToSpeechWidget extends StatelessWidget {
  const TextToSpeechWidget({super.key, required this.node});

  final WorkflowNode node;

  TextToSpeechNodeConfig get _config => node.config as TextToSpeechNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          title: 'Text vorlesen',
          child: _ModelChoice(node: node, config: _config),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_config.usesLanguageModel)
          _Panel(
            title: 'Sprachausgabe',
            child: _LanguageModelSpeech(node: node, config: _config),
          )
        else
          ModelInferenceWidget(
            node: node,
            speechDirection: SpeechModelDirection.textToSpeech,
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ModelChoice extends StatelessWidget {
  const _ModelChoice({required this.node, required this.config});

  final WorkflowNode node;
  final TextToSpeechNodeConfig config;

  @override
  Widget build(BuildContext context) {
    if (!_hasLanguageModelsProvider(context)) {
      return _picker(context, const [], false);
    }
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) => _picker(
        context,
        state.models,
        state.status == NodeLanguageModelsStatus.ready,
      ),
    );
  }

  Widget _picker(
    BuildContext context,
    List<LanguageModel> models,
    bool enabled,
  ) {
    return LanguageModelPickerField(
      models: models,
      selectedModelId: config.languageModelId,
      enabled: enabled,
      defaultOptionLabel: 'Lokales Modell (ONNX)',
      onChanged: (modelId) => context
          .read<TaskBuilderCubit>()
          .updateTextToSpeechLanguageModel(node.id, modelId),
    );
  }

  bool _hasLanguageModelsProvider(BuildContext context) {
    try {
      BlocProvider.of<NodeLanguageModelsCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _LanguageModelSpeech extends StatelessWidget {
  const _LanguageModelSpeech({required this.node, required this.config});

  final WorkflowNode node;
  final TextToSpeechNodeConfig config;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return BlocProvider(
      key: ValueKey('${node.id.value}-voices-${config.languageModelId}'),
      create: (_) =>
          serviceLocator<SpeechVoicesCubit>(param1: config.languageModelId)
            ..load(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechTextMappingField(
            nodeId: node.id.value,
            value: config.speechText,
            onChanged: (text) => cubit.updateTextToSpeechText(node.id, text),
          ),
          SpeechVoiceField(
            selectedVoiceId: config.voiceId,
            onChanged: (voiceId) =>
                cubit.updateTextToSpeechVoice(node.id, voiceId),
          ),
        ],
      ),
    );
  }
}
