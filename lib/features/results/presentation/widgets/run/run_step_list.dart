import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_activity.dart';
import '../../../domain/entities/run_result.dart';
import 'run_compact_values.dart';

/// Läufe ohne Graph: die Bausteine als knappe Schrittfolge, je Baustein nur
/// sein letzter Stand (ein Formular steht nicht als „wartet“ und „fertig“).
class RunStepList extends StatelessWidget {
  const RunStepList({super.key, required this.result});

  final RunResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _lastPerNode(result.topLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.results_no_graph.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < steps.length; index++)
          _Step(activity: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }

  List<TaskActivity> _lastPerNode(List<TaskActivity> nodes) {
    final byNode = <String, TaskActivity>{};
    for (final node in nodes) {
      byNode[node.nodeId ?? node.id.value] = node;
    }
    return byNode.values.toList();
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.activity, required this.isLast});

  final TaskActivity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final failed = activity.status == TaskActivityStatus.failed;
    final detail = failed
        ? activity.message ?? ''
        : RunCompactValues.line(activity);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(
                failed ? Icons.error_outline : Icons.check_circle_outline,
                size: AppSpacing.md + AppSpacing.xs,
                color: failed ? colors.error : colors.primary,
              ),
              if (!isLast)
                Expanded(
                  child: VerticalDivider(
                    width: AppSpacing.md + AppSpacing.xs,
                    color: colors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RunCompactValues.primitiveLabel(activity.primitive),
                    style: theme.textTheme.titleSmall,
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    SelectableText(
                      detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: failed ? colors.error : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
