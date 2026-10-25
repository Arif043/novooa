import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/dashboard_task.dart';
import '../cubits/task_start_cubit.dart';
import 'start_task_dialog.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final DashboardTask task;

  Future<void> _start(BuildContext context) async {
    final starter = context.read<TaskStartCubit>();
    final input = await showStartTaskDialog(context, task);
    if (input == null) return;
    await starter.start(task, context: input);
  }

  @override
  Widget build(BuildContext context) {
    final starting = context.select<TaskStartCubit, bool>(
      (cubit) => switch (cubit.state) {
        TaskStarting(task: final current) => current.id == task.id,
        _ => false,
      },
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Expanded(child: _TaskText(task: task)),
            const SizedBox(width: Spacing.md),
            FilledButton.icon(
              onPressed: starting ? null : () => _start(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(DashboardKeys.tasksStart.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskText extends StatelessWidget {
  const _TaskText({required this.task});

  final DashboardTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.title, style: theme.textTheme.titleMedium),
        if (task.objective.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            task.objective,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
