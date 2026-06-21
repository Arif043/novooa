import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'builder_panel.dart';

class NodeInspector extends StatelessWidget {
  const NodeInspector({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return BuilderPanel(
      title: 'Inspector',
      child: ListView(
        children: [
          _InspectorRow(label: 'Name', value: node.title),
          const SizedBox(height: AppSpacing.md),
          _InspectorRow(label: 'Primitive', value: node.primitive.label),
          const SizedBox(height: AppSpacing.md),
          _InspectorRow(label: 'Zweck', value: node.description),
          const SizedBox(height: AppSpacing.md),
          _InspectorRow(label: 'Genkit', value: _genkitTarget(node.primitive)),
        ],
      ),
    );
  }

  String _genkitTarget(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.prompt => 'ai.generate',
      WorkflowPrimitive.conditionalFlow => 'defineFlow + branch',
      WorkflowPrimitive.iterativeRefinement => 'defineFlow + loop',
      WorkflowPrimitive.toolCall => 'defineTool',
      WorkflowPrimitive.humanApproval => 'checkpoint',
      WorkflowPrimitive.validation => 'schema validation',
    };
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
