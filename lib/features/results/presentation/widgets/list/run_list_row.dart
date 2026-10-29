import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../localization/run_result_texts.dart';
import 'run_day_groups.dart';

/// Ein Lauf als kompakte Zeile: Uhrzeit, Status, Aufgabe und das Ergebnis in
/// einem Satz.
class RunListRow extends StatelessWidget {
  const RunListRow({
    super.key,
    required this.run,
    required this.selected,
    required this.onTap,
  });

  final TaskRun run;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = RunResultTexts.statusColor(colors, run.status);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Icon(
                    RunResultTexts.statusIcon(run.status),
                    size: AppSpacing.md + AppSpacing.xs,
                    color: statusColor,
                    semanticLabel: RunResultTexts.status(run.status),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(child: _Texts(run: run)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat.Hm(locale).format(runTime(run)),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = RunResultTexts.outcomeLine(run);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          run.taskTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs / 2),
        Text(
          summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
