import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../task_builder/domain/entities/workflow_node.dart';
import '../../../domain/entities/run_result.dart';
import '../../localization/run_result_texts.dart';
import 'run_result_round_selector.dart';

/// Ein Baustein im Ergebnisgraph: was er in diesem Lauf erlebt hat, der
/// erste Wert und die Zahl seiner Folgen. Nicht ausgeführte sind blass.
class RunResultNodeCard extends StatelessWidget {
  const RunResultNodeCard({
    super.key,
    required this.node,
    required this.state,
    required this.preview,
    required this.effectCount,
    required this.selected,
    required this.onTap,
    this.rounds,
  });

  final WorkflowNode node;
  final RunNodeState state;
  final String? preview;
  final int effectCount;
  final bool selected;
  final VoidCallback onTap;
  final RoundChoice? rounds;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _accent(colors);
    return Opacity(
      opacity: state == RunNodeState.notRun ? 0.45 : 1,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${node.title}, ${RunResultTexts.nodeState(state)}',
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: BorderSide(
              color: selected ? colors.primary : accent,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: _content(context, accent)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color accent) {
    final textTheme = Theme.of(context).textTheme;
    final choice = rounds;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: AppSpacing.md + AppSpacing.xs, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  node.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ),
              if (effectCount > 0) _EffectBadge(count: effectCount),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              preview ?? RunResultTexts.nodeState(state),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ),
          if (choice != null)
            RunResultRoundLine(choice: choice)
          else
            Text(
              RunResultTexts.nodeState(state),
              style: textTheme.labelSmall?.copyWith(color: accent),
            ),
        ],
      ),
    );
  }

  Color _accent(ColorScheme colors) => switch (state) {
    RunNodeState.succeeded => colors.primary,
    RunNodeState.failed => colors.error,
    RunNodeState.waiting => colors.tertiary,
    RunNodeState.skipped || RunNodeState.notRun => colors.outlineVariant,
  };

  IconData get _icon => switch (state) {
    RunNodeState.succeeded => CupertinoIcons.check_mark_circled,
    RunNodeState.failed => CupertinoIcons.exclamationmark_triangle,
    RunNodeState.waiting => CupertinoIcons.hand_raised,
    RunNodeState.skipped => CupertinoIcons.arrow_turn_down_right,
    RunNodeState.notRun => CupertinoIcons.minus_circle,
  };
}

class _EffectBadge extends StatelessWidget {
  const _EffectBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: count == 1
          ? LocaleKeys.results_effects_one.tr()
          : LocaleKeys.results_effects_many.tr(namedArgs: {'count': '$count'}),
      child: Badge.count(
        count: count,
        backgroundColor: colors.secondaryContainer,
        textColor: colors.onSecondaryContainer,
      ),
    );
  }
}
