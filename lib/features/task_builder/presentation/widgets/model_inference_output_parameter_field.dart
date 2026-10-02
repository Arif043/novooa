import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class ModelInferenceOutputParameterField extends StatelessWidget {
  const ModelInferenceOutputParameterField({
    super.key,
    required this.nodeId,
    required this.output,
    required this.descriptor,
    required this.value,
  });

  final NodeId nodeId;
  final ModelManifestOutput output;
  final ModelManifestOutputParameter descriptor;
  final ModelInferenceOutputParameter value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        key: ValueKey(
          '${nodeId.value}-${output.tensorName}-${descriptor.name}',
        ),
        initialValue: value.value.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: descriptor.label,
          helperText: '${descriptor.minimum} bis ${descriptor.maximum}',
        ),
        onChanged: (input) => _update(context, input),
      ),
    );
  }

  void _update(BuildContext context, String input) {
    final parsed = int.tryParse(input);
    if (parsed == null ||
        parsed < descriptor.minimum ||
        parsed > descriptor.maximum) {
      return;
    }
    context.read<TaskBuilderCubit>().updateModelInferenceOutputParameter(
      nodeId,
      value.copyWith(value: parsed),
    );
  }
}
