import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import 'branch_condition_editor.dart';
import 'condition_value_sources.dart';

/// Ersetzt die frühere einzelne "Wenn"-Freitexteingabe für Bedingter-
/// Ablauf-Bausteine ohne Entscheidungs-Prompt-Vorgänger: Baukasten-Bedingte
/// Zweige können hinzugefügt/entfernt werden, ein "Sonst"-Zweig greift
/// immer, wenn keiner davon zutrifft (siehe `addConditionBranch` in
/// `TaskBuilderConditionBranchMutations`).
class ConditionalBranchesEditor extends StatelessWidget {
  const ConditionalBranchesEditor({super.key, required this.node});

  final WorkflowNode node;

  ConditionalNodeConfig get _config => node.config as ConditionalNodeConfig;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskBuilderCubit>().state;
    final graph = state is TaskBuilderLoaded
        ? conditionSourceGraph(state.editingTask.graph, node.id)
        : WorkflowGraph.empty();
    final cubit = context.read<TaskBuilderCubit>();
    final conditioned = _config.branches
        .where((branch) => branch.condition != null)
        .toList();
    final sonst = _config.branches.where((branch) => branch.condition == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.ui_pfade_festlegen.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          LocaleKeys.ui_pruefe_werte_aus_vorherigen_bausteinen_der_erste.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (conditioned.isEmpty)
          _EmptyBranchesNotice(onAdd: () => cubit.addConditionBranch(node.id))
        else ...[
          for (final (index, branch) in conditioned.indexed)
            Padding(
              key: ValueKey(branch.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ConditionBranchCard(
                key: ValueKey(branch.id),
                // Fester Titel nach Position; was der Zweig prüft, zeigt
                // die Leinwand als Text der Bedingung.
                title: LocaleKeys.ui_condition_number.tr(
                  namedArgs: {'number': '${index + 1}'},
                ),
                branch: branch,
                graph: graph,
                onConditionChanged: (condition) => cubit.updateBranchCondition(
                  conditionalNodeId: node.id,
                  branchId: branch.id,
                  condition: condition,
                ),
                onRemove: () => cubit.removeConditionBranch(node.id, branch.id),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => cubit.addConditionBranch(node.id),
            icon: const Icon(Icons.add),
            label: Text(LocaleKeys.ui_bedingung_hinzufuegen.tr()),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: sonst.isNotEmpty,
              title: Text(LocaleKeys.ui_sonst_pfad_verwenden.tr()),
              subtitle: Text(
                LocaleKeys.ui_wird_ausgefuehrt_wenn_keine_bedingung_zutrifft
                    .tr(),
              ),
              onChanged: (enabled) async {
                if (enabled == null) return;
                if (!enabled &&
                    sonst.any((branch) => branch.graph.nodes.isNotEmpty)) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(LocaleKeys.ui_sonst_pfad_entfernen.tr()),
                      content: Text(
                        LocaleKeys
                            .ui_der_sonst_pfad_und_alle_darin_enthaltenen_bauste
                            .tr(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(LocaleKeys.ui_abbrechen.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(LocaleKeys.ui_pfad_entfernen.tr()),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                }
                await cubit.setOtherwiseBranchEnabled(node.id, enabled);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyBranchesNotice extends StatelessWidget {
  const _EmptyBranchesNotice({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.ui_no_condition_yet.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(LocaleKeys.ui_bedingung_hinzufuegen.tr()),
        ),
      ],
    );
  }
}

class _ConditionBranchCard extends StatelessWidget {
  const _ConditionBranchCard({
    super.key,
    required this.title,
    required this.branch,
    required this.graph,
    required this.onConditionChanged,
    required this.onRemove,
  });

  final String title;
  final ConditionalBranch branch;
  final WorkflowGraph graph;
  final ValueChanged<BranchCondition> onConditionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final condition = branch.condition;
    if (condition == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.ui_bedingung_entfernen.tr(),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            BranchConditionEditor(
              condition: condition,
              graph: graph,
              onChanged: onConditionChanged,
            ),
          ],
        ),
      ),
    );
  }
}
