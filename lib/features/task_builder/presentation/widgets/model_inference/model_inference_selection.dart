import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../domain/entities/node_config.dart';
import '../../../domain/entities/workflow_node.dart';
import '../../cubits/task_builder_cubit.dart';

/// Übernimmt ein Modell in den Baustein und lässt die Runtime es cachen.
void selectInferenceModel(
  BuildContext context,
  WorkflowNode node,
  ModelCatalogEntry model,
) {
  context.read<TaskBuilderCubit>().selectModelInference(
    node.id,
    model.id,
    _mappingsFor(model),
    _outputParametersFor(model),
    _settingsFor(model),
  );
  context.read<ModelCatalogCubit>().cacheModel(model.id);
}

List<ModelInferenceInputMapping> _mappingsFor(ModelCatalogEntry model) => model
    .inputs
    .where((input) => input.requiresWorkflowMapping)
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

List<ModelInferenceOutputParameter> _outputParametersFor(
  ModelCatalogEntry model,
) => model.outputs
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

List<ModelInferenceSetting> _settingsFor(ModelCatalogEntry model) => model
    .settings
    .map(
      (parameter) => ModelInferenceSetting(
        name: parameter.name,
        valueTemplate: '${parameter.control.initialValue()}',
      ),
    )
    .toList(growable: false);
