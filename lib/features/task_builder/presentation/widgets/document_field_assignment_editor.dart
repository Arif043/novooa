import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class DocumentFieldAssignmentEditor extends StatelessWidget {
  const DocumentFieldAssignmentEditor({
    super.key,
    required this.nodeId,
    required this.index,
    required this.assignment,
    required this.canRemove,
  });

  final NodeId nodeId;
  final int index;
  final DocumentFieldAssignment assignment;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Feldzuordnung ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: assignment.field,
            decoration: const InputDecoration(labelText: 'Feld'),
            onChanged: (value) => _update(context, field: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: assignment.value,
            decoration: const InputDecoration(labelText: 'Wert'),
            onChanged: (value) => _update(context, value: value),
          ),
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Feld entfernen',
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .removeSaveDocumentField(nodeId, index),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ),
        ],
      ),
    );
  }

  void _update(BuildContext context, {String? field, String? value}) {
    context.read<TaskBuilderCubit>().updateSaveDocumentField(
      nodeId,
      index,
      assignment.copyWith(field: field, value: value),
    );
  }
}
