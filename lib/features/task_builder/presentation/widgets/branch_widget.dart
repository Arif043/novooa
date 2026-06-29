import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class BranchWidget extends StatelessWidget {
  const BranchWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        children: [
          Text('Wenn', style: SyscatTheme.taskBody),
          for (int choiceIndex = 0; choiceIndex < (node.config as ConditionalNodeConfig).choices.length; choiceIndex++)
            Text((node.config as ConditionalNodeConfig).choices[choiceIndex]),
        ],
      ));
  }
}