import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/task_run.dart';
import 'run_detail_sheet.dart';

class RunCard extends StatelessWidget {
  const RunCard({super.key, required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMd(context.locale.toLanguageTag()).add_Hm();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: Spacing.md,
        onTap: () => showRunDetailSheet(context, run),
        title: Text(run.taskTitle, style: theme.textTheme.titleMedium),
        subtitle: Text(time.format(run.updatedAt.toLocal())),
        trailing: RunStatusChip(status: run.status),
      ),
    );
  }
}

class RunStatusChip extends StatelessWidget {
  const RunStatusChip({super.key, required this.status});

  final RunStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (status) {
      RunStatus.waitingForApproval => colors.tertiaryContainer,
      RunStatus.failed || RunStatus.rejected => colors.errorContainer,
      RunStatus.succeeded => colors.primaryContainer,
      RunStatus.queued || RunStatus.running => colors.surfaceContainerHighest,
    };
    return Chip(
      label: Text(DashboardKeys.runStatus(status.name).tr()),
      backgroundColor: background,
      side: BorderSide.none,
    );
  }
}
