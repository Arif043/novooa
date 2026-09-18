import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class ModelInferenceInputMappingField extends StatelessWidget {
  const ModelInferenceInputMappingField({
    super.key,
    required this.nodeId,
    required this.input,
    required this.mapping,
  });

  final NodeId nodeId;
  final ModelManifestInput input;
  final ModelInferenceInputMapping mapping;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 720
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _fields(context),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _expandedFields(context),
              ),
      ),
    );
  }

  List<Widget> _fields(BuildContext context) => [
    _nameField(),
    const SizedBox(height: AppSpacing.sm),
    _workflowMappingField(context),
    const SizedBox(height: AppSpacing.sm),
    _dataTypeField(),
  ];

  List<Widget> _expandedFields(BuildContext context) => [
    Expanded(child: _nameField()),
    const SizedBox(width: AppSpacing.sm),
    Expanded(flex: 2, child: _workflowMappingField(context)),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _dataTypeField()),
  ];

  Widget _nameField() => TextFormField(
    initialValue: input.name,
    readOnly: true,
    decoration: const InputDecoration(labelText: 'Name'),
  );

  Widget _workflowMappingField(BuildContext context) => TextFormField(
    key: ValueKey('${nodeId.value}-${input.name}'),
    initialValue: mapping.workflowMapping,
    decoration: const InputDecoration(
      labelText: 'Workflow-Mapping',
      hintText: '{{eingabe.value}} oder {{global.eingabe.value}}',
    ),
    onChanged: (workflowMapping) =>
        context.read<TaskBuilderCubit>().updateModelInferenceWorkflowMapping(
          nodeId,
          mapping.copyWith(workflowMapping: workflowMapping),
        ),
  );

  Widget _dataTypeField() => TextFormField(
    initialValue: input.source.label,
    readOnly: true,
    decoration: const InputDecoration(labelText: 'Datentyp'),
  );
}
