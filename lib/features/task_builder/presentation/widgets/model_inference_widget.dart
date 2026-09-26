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
import 'model_inference_input_mapping_field.dart';
import 'model_inference_output_configuration.dart';

enum SpeechModelDirection { textToSpeech, speechToText }

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
  const _ModelInferenceCatalog({required this.node, required this.speechDirection});

  final WorkflowNode node;
  final SpeechModelDirection? speechDirection;

  @override
  Widget build(BuildContext context) {
    if (!_hasCatalog(context)) {
      return _ModelInferenceContent(
        node: node,
        models: const [],
        speechDirection: speechDirection,
      );
    }
    return BlocBuilder<ModelCatalogCubit, ModelCatalogState>(
      builder: (context, state) =>
          _ModelInferenceContent(
            node: node,
            models: state.entries,
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
    required this.models,
    required this.speechDirection,
  });

  final WorkflowNode node;
  final List<ModelCatalogEntry> models;
  final SpeechModelDirection? speechDirection;

  ModelInferenceNodeConfig get _config => node.config as ModelInferenceNodeConfig;

  List<ModelCatalogEntry> get _availableModels => switch (speechDirection) {
    SpeechModelDirection.textToSpeech =>
      models.where(_isTextToSpeechModel).toList(growable: false),
    SpeechModelDirection.speechToText =>
      models.where(_isSpeechToTextModel).toList(growable: false),
    null => models,
  };

  @override
  Widget build(BuildContext context) {
    final availableModels = _availableModels;
    final model = _modelFor(_config.modelId, availableModels);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          _ModelSelection(node: node, models: availableModels, selectedModel: model),
          if (model != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Modelleingaben',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final input in model.inputs)
              ModelInferenceInputMappingField(
                nodeId: node.id,
                input: input,
                mapping: _mappingFor(input),
              ),
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

  ModelCatalogEntry? _modelFor(
    String modelId,
    List<ModelCatalogEntry> availableModels,
  ) {
    for (final model in availableModels) {
      if (model.id == modelId) return model;
    }
    return null;
  }

  String get _title => switch (speechDirection) {
    SpeechModelDirection.textToSpeech => 'Text vorlesen',
    SpeechModelDirection.speechToText => 'Audio transkribieren',
    null => 'Modell ausführen',
  };

  bool _isTextToSpeechModel(ModelCatalogEntry model) =>
      model.outputs.any((output) => output.workflowType == 'audio');

  bool _isSpeechToTextModel(ModelCatalogEntry model) =>
      model.inputs.any((input) => input.source == ModelInputSource.audio);

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
    required this.models,
    required this.selectedModel,
  });

  final WorkflowNode node;
  final List<ModelCatalogEntry> models;
  final ModelCatalogEntry? selectedModel;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) return _manualModelIdField(context);
    return DropdownButtonFormField<String>(
      initialValue: selectedModel?.id,
      decoration: const InputDecoration(labelText: 'Modell'),
      items: models.map(_itemFor).toList(growable: false),
      onChanged: (modelId) => _select(context, modelId),
    );
  }

  Widget _manualModelIdField(BuildContext context) {
    final config = node.config as ModelInferenceNodeConfig;
    return TextFormField(
      initialValue: config.modelId,
      decoration: const InputDecoration(hintText: 'Modell-ID'),
      onChanged: (modelId) => context
          .read<TaskBuilderCubit>()
          .updateModelInference(node.id, modelId),
    );
  }

  DropdownMenuItem<String> _itemFor(ModelCatalogEntry model) {
    return DropdownMenuItem(value: model.id, child: Text(model.title));
  }

  void _select(BuildContext context, String? modelId) {
    if (modelId == null) return;
    final model = models.firstWhere((entry) => entry.id == modelId);
    final mappings = model.inputs
        .map(
          (input) => ModelInferenceInputMapping(
            modelInputName: input.name,
            workflowMapping: '',
            sourceType: input.source.name,
            dataType: input.dataType,
            shape: input.shape,
          ),
        )
        .toList(growable: false);
    final outputParameters = model.outputs
        .expand(
          (output) => output.parameters.map(
            (parameter) => ModelInferenceOutputParameter(
              outputName: output.tensorName,
              name: parameter.name,
              value: parameter.defaultValue,
            ),
          ),
        )
        .toList(growable: false);
    context.read<TaskBuilderCubit>().selectModelInference(
      node.id,
      model.id,
      mappings,
      outputParameters,
    );
  }
}
