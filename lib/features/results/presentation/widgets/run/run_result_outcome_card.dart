import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../../../activity/domain/entities/task_activity.dart';
import '../../../../activity/presentation/widgets/node_activity_failure.dart';
import '../../../domain/entities/run_result.dart';

/// Was am Ende herauskam — oder woran der Lauf gescheitert ist.
class RunResultOutcomeCard extends StatelessWidget {
  const RunResultOutcomeCard({super.key, required this.result});

  final RunResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = result.topLevel
        .where((node) => node.status == TaskActivityStatus.failed)
        .lastOrNull;
    final output = result.run.finalOutput?.trim() ?? '';
    return LuminousCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              failed == null
                  ? LocaleKeys.results_result_title.tr()
                  : LocaleKeys.results_failure_title.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (failed != null)
              NodeActivityFailure(
                message: failed.message ?? result.run.message ?? '',
                failureCode: failed.failureCode,
                failureDetails: failed.failureDetails,
              )
            else if (output.isNotEmpty)
              SelectableText(output, style: theme.textTheme.bodyMedium)
            else
              Text(
                LocaleKeys.results_no_output.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
