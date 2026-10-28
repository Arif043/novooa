import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../localization/run_result_texts.dart';
import 'run_status_chip.dart';

/// Ein Lauf in der Liste: Aufgabe, wann, wie lange, von wem, und sein Status.
class RunResultListCard extends StatelessWidget {
  const RunResultListCard({super.key, required this.run, required this.onTap});

  final TaskRun run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuminousCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LuminousCardHeading(
                leading: LuminousIconBadge(
                  icon: RunResultTexts.statusIcon(run.status),
                ),
                title: run.taskTitle,
                subtitle: RunResultTexts.meta(context, run),
                subtitleMaxLines: 2,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            RunStatusChip(status: run.status),
          ],
        ),
      ),
    );
  }
}
