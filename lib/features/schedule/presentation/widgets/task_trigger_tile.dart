import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../cubits/schedule_cubit.dart';
import 'schedule_formatters.dart';

class TaskTriggerTile extends StatefulWidget {
  const TaskTriggerTile({
    super.key,
    required this.trigger,
    required this.cubit,
  });
  final TaskTrigger trigger;
  final ScheduleCubit cubit;
  @override
  State<TaskTriggerTile> createState() => _TaskTriggerTileState();
}

class _TaskTriggerTileState extends State<TaskTriggerTile> {
  bool _busy = false;

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Die Änderung konnte nicht gespeichert werden. Bitte versuche es erneut.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Auslöser löschen?'),
        content: Text(
          '„${widget.trigger.taskTitle}“ wird durch diesen Auslöser nicht mehr gestartet. Die Aufgabe bleibt erhalten.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(() => widget.cubit.deleteTrigger(widget.trigger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.trigger;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(trigger),
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trigger.taskTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        triggerLabel(trigger),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  triggerStatusLabel(trigger),
                  style: theme.textTheme.bodySmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trigger.enabled ? 'Aktiv' : 'Pausiert',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Auslöser für ${trigger.taskTitle}',
                      child: CupertinoSwitch(
                        value: trigger.enabled,
                        activeTrackColor: SyscatTheme.primaryOrange,
                        onChanged: _busy
                            ? null
                            : (value) => _perform(
                                () => widget.cubit.setEnabled(trigger, value),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: CupertinoActivityIndicator(),
                      )
                    else
                      IconButton(
                        tooltip: 'Auslöser löschen',
                        onPressed: _delete,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Icon(
                          CupertinoIcons.trash,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(TaskTrigger trigger) {
  if (trigger.type == TriggerType.schedule) return CupertinoIcons.clock;
  return switch (trigger.event?.source) {
    EventTriggerSource.emailReceived => CupertinoIcons.envelope,
    EventTriggerSource.smsMessageReceived => CupertinoIcons.chat_bubble,
    EventTriggerSource.whatsappMessageReceived => CupertinoIcons.chat_bubble_2,
    EventTriggerSource.fileCreated => CupertinoIcons.doc,
    EventTriggerSource.fileVersionCreated => CupertinoIcons.doc_on_doc,
    EventTriggerSource.fileDeleted => CupertinoIcons.trash,
    EventTriggerSource.webhookReceived => CupertinoIcons.link,
    null => CupertinoIcons.bolt,
  };
}
