import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../domain/entities/node_config.dart';
import '../../../domain/entities/workflow_node.dart';
import '../../cubits/task_builder_cubit.dart';
import '../model_inference_input_mapping_field.dart';
import '../speech_text_mapping_field.dart';
import 'model_search_filter.dart';

class ModelInferenceInputSection extends StatelessWidget {
  const ModelInferenceInputSection({
    super.key,
    required this.node,
    required this.model,
    required this.speechDirection,
    required this.mappings,
    required this.mappingFor,
  });

  final WorkflowNode node;
  final ModelCatalogEntry model;
  final SpeechModelDirection? speechDirection;
  final List<ModelInferenceInputMapping> mappings;
  final ModelInferenceInputMapping Function(ModelManifestInput) mappingFor;

  @override
  Widget build(BuildContext context) {
    if (speechDirection == SpeechModelDirection.textToSpeech) {
      return SpeechTextMappingField(
        nodeId: node.id.value,
        value: _textMapping().workflowMapping,
        onChanged: (value) => _updateTextMappings(context, value),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.ui_modelleingaben.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final input in model.inputs.where(
          (input) => input.requiresWorkflowMapping,
        ))
          ModelInferenceInputMappingField(
            nodeId: node.id,
            input: input,
            mapping: mappingFor(input),
          ),
      ],
    );
  }

  ModelInferenceInputMapping _textMapping() {
    final input = model.inputs.firstWhere(
      (input) =>
          input.requiresWorkflowMapping &&
          input.source == ModelInputSource.text,
    );
    return mappingFor(input);
  }

  void _updateTextMappings(BuildContext context, String value) {
    final updated = model.inputs
        .where((input) => input.requiresWorkflowMapping)
        .map((input) {
          final mapping = mappingFor(input);
          return input.source == ModelInputSource.text
              ? mapping.copyWith(workflowMapping: value)
              : mapping;
        })
        .toList(growable: false);
    context.read<TaskBuilderCubit>().updateModelInferenceWorkflowMappings(
      node.id,
      updated,
    );
  }
}
