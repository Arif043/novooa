import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class ForEachWidget extends StatelessWidget {
  const ForEachWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as ForEachNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Für jedes Element', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: config.itemsPointer,
            decoration: const InputDecoration(hintText: 'JSON-Pointer, z. B. /items'),
            onChanged: (value) => context.read<TaskBuilderCubit>()
                .updateForEachPointer(node.id, value),
          ),
        ],
      ),
    );
  }
}
