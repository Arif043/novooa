import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'model_inference/model_inference_input_section.dart';
import 'model_inference/model_picker_field.dart';
import 'model_inference/model_search_filter.dart';
import 'model_input_parameter_configuration.dart';
import 'model_inference_output_configuration.dart';

export 'model_inference/model_search_filter.dart' show SpeechModelDirection;

class ModelInferenceWidget extends StatelessWidget {
  const ModelInferenceWidget({
    super.key,
    required this.node,
    this.speechDirection,
  });

  final WorkflowNode node;
  final SpeechModelDirection? speechDirection;

  @override
  Widget build(BuildContext context) {
    return _ModelInferenceCatalog(node: node, speechDirection: speechDirection);
  }
}

class _ModelInferenceCatalog extends StatelessWidget {
  const _ModelInferenceCatalog({
    required this.node,
    required this.speechDirection,
  });

  final WorkflowNode node;
  final SpeechModelDirection? speechDirection;

  @override
  Widget build(BuildContext context) {
    if (!_hasCatalog(context)) {
      return _ModelInferenceContent(
        node: node,
        state: null,
        speechDirection: speechDirection,
      );
    }
    return BlocBuilder<ModelCatalogCubit, ModelCatalogState>(
      builder: (context, state) => _ModelInferenceContent(
        node: node,
        state: state,
        speechDirection: speechDirection,
      ),
    );
  }

  bool _hasCatalog(BuildContext context) {
    try {
      BlocProvider.of<ModelCatalogCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _ModelInferenceContent extends StatelessWidget {
  const _ModelInferenceContent({
    required this.node,
    required this.state,
    required this.speechDirection,
  });

  final WorkflowNode node;
  final ModelCatalogState? state;
  final SpeechModelDirection? speechDirection;

  ModelInferenceNodeConfig get _config =>
      node.config as ModelInferenceNodeConfig;

  @override
  Widget build(BuildContext context) {
    final model = state?.entryById(_config.modelId);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          _ModelSelection(
            node: node,
            state: state,
            speechDirection: speechDirection,
          ),
          if (model != null) ...[
            const SizedBox(height: AppSpacing.md),
            ModelInferenceInputSection(
              node: node,
              model: model,
              speechDirection: speechDirection,
              mappings: _config.inputMappings,
              mappingFor: _mappingFor,
            ),
            if (model.settings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ModelSettingConfiguration(
                nodeId: node.id,
                settings: model.settings,
                values: _config.settings,
              ),
            ],
            ModelInferenceOutputConfiguration(
              nodeId: node.id,
              outputs: model.outputs,
              parameters: _config.outputParameters,
            ),
          ],
        ],
      ),
    );
  }

  String get _title => switch (speechDirection) {
    SpeechModelDirection.textToSpeech => 'Text vorlesen',
    SpeechModelDirection.speechToText => 'Audio transkribieren',
    null => 'Modell ausführen',
  };

  ModelInferenceInputMapping _mappingFor(ModelManifestInput input) {
    for (final mapping in _config.inputMappings) {
      if (mapping.modelInputName == input.name && _isComplete(mapping)) {
        return mapping;
      }
    }
    return ModelInferenceInputMapping(
      modelInputName: input.name,
      workflowMapping: '',
      sourceType: input.source.name,
      dataType: input.dataType,
      shape: input.shape,
    );
  }

  bool _isComplete(ModelInferenceInputMapping mapping) {
    return mapping.sourceType.isNotEmpty &&
        mapping.dataType.isNotEmpty &&
        mapping.shape.isNotEmpty;
  }
}

class _ModelSelection extends StatelessWidget {
  const _ModelSelection({
    required this.node,
    required this.state,
    required this.speechDirection,
  });

  final WorkflowNode node;
  final ModelCatalogState? state;
  final SpeechModelDirection? speechDirection;

  @override
  Widget build(BuildContext context) {
    final config = node.config as ModelInferenceNodeConfig;
    final catalog = state;
    if (catalog != null) {
      return ModelPickerField(
        node: node,
        modelId: config.modelId,
        state: catalog,
        speechDirection: speechDirection,
      );
    }
    // Ohne Modellkatalog (z. B. Cloud) bleibt nur die Eingabe der Modell-ID.
    return TextFormField(
      initialValue: config.modelId,
      decoration: const InputDecoration(hintText: 'Modell-ID'),
      onChanged: (modelId) => context
          .read<TaskBuilderCubit>()
          .updateModelInference(node.id, modelId),
    );
  }
}
