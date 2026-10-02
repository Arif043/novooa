import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'model_inference_widget.dart';
import 'speech_node_parts.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

/// „Sprache zu Text": entweder über ein verbundenes Sprachmodell (Google AI,
/// ElevenLabs Scribe, OpenAI-kompatibel) oder über ein lokales ONNX-Modell.
/// Die Sprachmodelle sind bewusst nicht gefiltert; passt ein Modell nicht,
/// steht der Fehler des Anbieters in der Aktivität.
class SpeechToTextWidget extends StatelessWidget {
  const SpeechToTextWidget({super.key, required this.node});

  final WorkflowNode node;

  SpeechToTextNodeConfig get _config => node.config as SpeechToTextNodeConfig;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpeechNodePanel(
          title: 'Sprache zu Text',
          child: SpeechLanguageModelChoice(
            selectedModelId: _config.languageModelId,
            onChanged: (modelId) =>
                cubit.updateSpeechToTextLanguageModel(node.id, modelId),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_config.usesLanguageModel)
          SpeechNodePanel(
            title: 'Audioaufnahme',
            child: TemplateExpressionTextField(
              key: ValueKey('${node.id.value}-speech-audio'),
              value: _config.audioTemplate,
              suggestions: TemplateExpressionScope.suggestionsOf(context),
              decoration: const InputDecoration(
                labelText: 'Audiodatei',
                hintText: '{{aufnahme.value}}',
              ),
              onChanged: (value) =>
                  cubit.updateSpeechToTextAudio(node.id, value),
            ),
          )
        else
          ModelInferenceWidget(
            node: node,
            speechDirection: SpeechModelDirection.speechToText,
          ),
      ],
    );
  }
}
