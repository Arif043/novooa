import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../localization/run_result_texts.dart';

/// Filter nach Status; nur Status, die vorkommen, werden angeboten.
class ResultsStatusFilter extends StatelessWidget {
  const ResultsStatusFilter({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onSelected,
  });

  final Set<TaskRunStatus> statuses;
  final TaskRunStatus? selected;
  final ValueChanged<TaskRunStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: Text(LocaleKeys.results_filter_all.tr()),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final status in TaskRunStatus.values)
          if (statuses.contains(status))
            ChoiceChip(
              label: Text(RunResultTexts.status(status)),
              selected: selected == status,
              onSelected: (_) => onSelected(status),
            ),
      ],
    );
  }
}
