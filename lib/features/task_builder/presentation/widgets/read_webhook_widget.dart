import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class ReadWebhookWidget extends StatelessWidget {
  const ReadWebhookWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Webhook-Ereignis lesen', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Gilt für Aufgaben, die ein Webhook-Auslöser startet. '
            'Der Inhalt steht unter dem Ausgabenamen, z. B. '
            '{{ereignis.bestellung}}.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Ausgaben: Inhalt, Methode, Query, Kopfzeilen, Zeitpunkt'),
        ],
      ),
    );
  }
}
