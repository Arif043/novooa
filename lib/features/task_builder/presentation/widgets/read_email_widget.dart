import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class ReadEmailWidget extends StatelessWidget {
  const ReadEmailWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('E-Mail lesen', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          const Text('Ausgaben: Absender, Betreff, Nachricht, Ankunftszeit'),
        ],
      ),
    );
  }
}
