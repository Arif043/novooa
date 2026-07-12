import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class NodePlaceholder extends StatelessWidget {
  const NodePlaceholder({
    super.key,
    required this.onAccept,
    this.allowedPrimitives,
  });

  final ValueChanged<WorkflowPrimitive> onAccept;
  final Set<WorkflowPrimitive>? allowedPrimitives;

  @override
  Widget build(BuildContext context) {
    return DragTarget<WorkflowPrimitive>(
      onWillAcceptWithDetails: (details) {
        return allowedPrimitives?.contains(details.data) ?? true;
      },
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: .infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: candidateData.isEmpty
                ? SyscatTheme.glassSurface
                : SyscatTheme.primaryOrangeHover,
            border: Border.all(
              color: candidateData.isEmpty
                  ? SyscatTheme.borderLight
                  : SyscatTheme.primaryOrange,
              width: candidateData.isEmpty ? 1 : 2,
            ),
            borderRadius: .circular(16),
          ),
          child: const Center(
            child: Icon(Icons.add, color: SyscatTheme.primaryOrange),
          ),
        );
      },
    );
  }
}
