import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'builder_panel.dart';

class PrimitivePalette extends StatelessWidget {
  const PrimitivePalette({super.key, required this.onPrimitiveAdded});

  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;

  @override
  Widget build(BuildContext context) {
    return BuilderPanel(
      title: 'Bausteine',
      child: ListView.separated(
        itemCount: WorkflowPrimitive.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final primitive = WorkflowPrimitive.values[index];
          return _PrimitiveTile(
            primitive: primitive,
            onTap: () => onPrimitiveAdded(primitive),
          );
        },
      ),
    );
  }
}

class _PrimitiveTile extends StatelessWidget {
  const _PrimitiveTile({required this.primitive, required this.onTap});

  final WorkflowPrimitive primitive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${primitive.label} hinzufügen',
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(_iconFor(primitive)),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(primitive.label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  IconData _iconFor(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.prompt => Icons.chat_bubble_outline,
      WorkflowPrimitive.conditionalFlow => Icons.account_tree_outlined,
      WorkflowPrimitive.iterativeRefinement => Icons.autorenew,
      WorkflowPrimitive.toolCall => Icons.construction_outlined,
      WorkflowPrimitive.humanApproval => Icons.verified_user_outlined,
      WorkflowPrimitive.validation => Icons.rule,
    };
  }
}
