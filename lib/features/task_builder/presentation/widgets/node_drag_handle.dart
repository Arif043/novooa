import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class NodeDragHandle extends StatelessWidget {
  const NodeDragHandle({
    super.key,
    required this.node,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final WorkflowNode node;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    return Draggable<NodeId>(
      data: node.id,
      feedback: const SizedBox.shrink(),
      childWhenDragging: _handle(context),
      onDragStarted: () {
        context.read<TaskBuilderCubit>().selectNode(node.id);
        onDragStarted();
      },
      onDragEnd: (_) => onDragEnded(),
      child: _handle(context),
    );
  }

  Widget _handle(BuildContext context) {
    return Semantics(
      label: 'Baustein tauschen',
      button: true,
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: Icon(
          Icons.drag_indicator,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
