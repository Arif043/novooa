import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import 'model_inference_output_parameter_field.dart';

class ModelInferenceOutputConfiguration extends StatelessWidget {
  const ModelInferenceOutputConfiguration({
    super.key,
    required this.nodeId,
    required this.outputs,
    required this.parameters,
  });

  final NodeId nodeId;
  final List<ModelManifestOutput> outputs;
  final List<ModelInferenceOutputParameter> parameters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Modellausgabe', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final output in outputs)
          _WorkflowOutputDescription(output: output),
        for (final output in outputs)
          for (final descriptor in output.parameters)
            ModelInferenceOutputParameterField(
              nodeId: nodeId,
              output: output,
              descriptor: descriptor,
              value: _valueFor(output, descriptor),
            ),
      ],
    );
  }

  ModelInferenceOutputParameter _valueFor(
    ModelManifestOutput output,
    ModelManifestOutputParameter descriptor,
  ) {
    for (final parameter in parameters) {
      if (parameter.outputName == output.tensorName &&
          parameter.name == descriptor.name) {
        return parameter;
      }
    }
    return ModelInferenceOutputParameter(
      outputName: output.tensorName,
      name: descriptor.name,
      value: descriptor.defaultValue,
    );
  }
}

class _WorkflowOutputDescription extends StatelessWidget {
  const _WorkflowOutputDescription({required this.output});

  final ModelManifestOutput output;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        '${output.workflowName} - ${output.workflowTypeLabel}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
