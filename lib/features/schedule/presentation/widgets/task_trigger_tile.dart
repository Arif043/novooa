import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../cubits/schedule_cubit.dart';
import 'schedule_formatters.dart';

class TaskTriggerTile extends StatelessWidget {
  const TaskTriggerTile({
    super.key,
    required this.trigger,
    required this.cubit,
  });

  final TaskTrigger trigger;
  final ScheduleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(trigger), color: colorScheme.primary),
                const Spacer(),
                Switch(
                  value: trigger.enabled,
                  onChanged: (value) => cubit.setEnabled(trigger, value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              trigger.taskTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(triggerLabel(trigger)),
            const Spacer(),
            Text(
              triggerStatusLabel(trigger),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Trigger löschen',
                onPressed: () => cubit.deleteTrigger(trigger),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(TaskTrigger trigger) {
  if (trigger.type == TriggerType.schedule) return Icons.schedule_outlined;
  return switch (trigger.event?.source) {
    EventTriggerSource.emailReceived => Icons.alternate_email,
    EventTriggerSource.smsMessageReceived => Icons.sms_outlined,
    EventTriggerSource.whatsappMessageReceived => Icons.chat_outlined,
    EventTriggerSource.fileCreated => Icons.note_add_outlined,
    EventTriggerSource.webhookReceived => Icons.webhook_outlined,
    null => Icons.bolt_outlined,
  };
}
