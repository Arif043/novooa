import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_predecessor.dart';
import 'package:syscat2/features/task_builder/domain/services/decision_branch_coverage.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

/// Zeigt, welche Antworten des direkt vorherigen Entscheidungs-Prompts noch
/// keinen Zweig haben, und ergänzt sie per Klick. Ändert nie etwas still.
class DecisionCoverageHint extends StatelessWidget {
  const DecisionCoverageHint({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final missing = _missingAnswers(context);
    if (missing.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.ui_decision_answers_without_branch.tr(
                    namedArgs: {'answers': missing.join(', ')},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(AppSpacing.xxl),
            ),
            icon: const Icon(Icons.add),
            label: Text(LocaleKeys.ui_add_missing_branches.tr()),
            onPressed: () => context
                .read<TaskBuilderCubit>()
                .addMissingDecisionBranches(node.id),
          ),
        ],
      ),
    );
  }

  /// Liest Ablauf und Vorgänger aus dem aktuellen Zustand, damit der Hinweis
  /// nach „Fehlende Zweige ergänzen“ sofort verschwindet.
  List<String> _missingAnswers(BuildContext context) {
    final state = context.watch<TaskBuilderCubit>().state;
    if (state is! TaskBuilderLoaded) return const [];
    final graph = state.editingTask.graph;
    final current = owningGraphOf(graph, node.id)?.nodeOrNull(node.id);
    final config = current?.config;
    if (config is! ConditionalNodeConfig) return const [];
    final prompt = directPredecessorOf(graph, node.id);
    if (prompt?.config case PromptNodeConfig(
      outputType: PromptOutputType.decision,
      :final choices,
    )) {
      return missingDecisionAnswers(config, prompt!.primaryOutputName, choices);
    }
    return const [];
  }
}
