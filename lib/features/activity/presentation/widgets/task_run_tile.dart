import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';

class TaskRunTile extends StatelessWidget {
  const TaskRunTile({super.key, required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: Icon(_icon, color: _color(colorScheme)),
      title: Text(run.taskTitle, style: textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(_subtitle),
      ),
      trailing: Text(_statusLabel),
    );
  }

  IconData get _icon {
    return switch (run.status) {
      TaskRunStatus.waitingForApproval => Icons.pending_actions_outlined,
      TaskRunStatus.rejected => Icons.block_outlined,
      TaskRunStatus.failed => Icons.error_outline,
      TaskRunStatus.succeeded => Icons.check_circle_outline,
      TaskRunStatus.running => Icons.play_circle_outline,
      TaskRunStatus.queued => Icons.schedule_outlined,
    };
  }

  Color _color(ColorScheme colorScheme) {
    return switch (run.status) {
      TaskRunStatus.waitingForApproval => colorScheme.secondary,
      TaskRunStatus.rejected || TaskRunStatus.failed => colorScheme.error,
      TaskRunStatus.succeeded => colorScheme.tertiary,
      TaskRunStatus.running || TaskRunStatus.queued => colorScheme.primary,
    };
  }

  String get _statusLabel {
    return switch (run.status) {
      TaskRunStatus.queued => 'Wartet',
      TaskRunStatus.running => 'Läuft',
      TaskRunStatus.waitingForApproval =>
        run.requiresDialogInput ? 'Eingabe' : 'Freigabe',
      TaskRunStatus.rejected => 'Abgelehnt',
      TaskRunStatus.succeeded => 'Fertig',
      TaskRunStatus.failed => 'Fehler',
    };
  }

  String get _subtitle {
    final detail = run.message ?? run.finalOutput ?? run.waitingNodeId;
    if (detail == null || detail.trim().isEmpty) return run.id.value;
    return detail;
  }
}
