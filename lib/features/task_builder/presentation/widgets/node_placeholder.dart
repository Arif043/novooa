import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class NodePlaceholder extends StatelessWidget {
  const NodePlaceholder({super.key, required this.onAccept});

  final ValueChanged<WorkflowPrimitive> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<WorkflowPrimitive>(
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: .infinity,
          padding: .all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SyscatTheme.primaryOrange, width: 2),
            borderRadius: .circular(8),
          ),
          child: Center(child: Icon(Icons.add)),
        );
      },
    );
  }
}
