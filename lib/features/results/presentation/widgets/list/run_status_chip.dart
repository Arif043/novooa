import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../localization/run_result_texts.dart';

class RunStatusChip extends StatelessWidget {
  const RunStatusChip({super.key, required this.status});

  final TaskRunStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = RunResultTexts.statusColor(theme.colorScheme, status);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              RunResultTexts.statusIcon(status),
              size: AppSpacing.md,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              RunResultTexts.status(status),
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
