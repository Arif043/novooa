import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../localization/run_result_texts.dart';
import '../list/run_status_chip.dart';

/// Zurück, Status, Aufgabe und die Kennzahlen des Laufs.
class RunResultHeader extends StatelessWidget {
  const RunResultHeader({super.key, required this.run, this.showBack = true});

  final TaskRun run;

  /// In der Detailspalte gibt es kein Zurück.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (showBack) ...[
          BackButton(onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  run.taskTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                RunResultTexts.meta(context, run),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        RunStatusChip(status: run.status),
      ],
    );
  }
}
