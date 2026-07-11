import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/task_builder_cubit.dart';
import '../../domain/entities/workflow_node.dart';

class DeletableNodeWidget extends StatelessWidget {
  const DeletableNodeWidget({
    super.key,
    required this.node,
    required this.child,
  });

  final WorkflowNode node;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: IconButton(
            tooltip: 'Baustein löschen',
            onPressed: () =>
                context.read<TaskBuilderCubit>().removeNode(node.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );
  }
}
