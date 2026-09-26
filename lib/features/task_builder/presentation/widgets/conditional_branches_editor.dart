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
        Text('Pfade festlegen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Prüfe Werte aus vorherigen Bausteinen. Der erste passende Pfad wird ausgeführt.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (conditioned.isEmpty)
          _EmptyBranchesNotice(onAdd: () => cubit.addConditionBranch(node.id))
        else ...[
          for (final branch in conditioned)
            Padding(
              key: ValueKey(branch.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ConditionBranchCard(
                key: ValueKey(branch.id),
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
            label: const Text('Bedingung hinzufügen'),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: sonst.isNotEmpty,
              title: const Text('Sonst-Pfad verwenden'),
              subtitle: const Text(
                'Wird ausgeführt, wenn keine Bedingung zutrifft.',
              ),
              onChanged: (enabled) async {
                if (enabled == null) return;
                if (!enabled &&
                    sonst.any((branch) => branch.graph.nodes.isNotEmpty)) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Sonst-Pfad entfernen?'),
                      content: const Text(
                        'Der Sonst-Pfad und alle darin enthaltenen Bausteine werden entfernt.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Pfad entfernen'),
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
          'Noch keine Bedingung — ohne Bedingung läuft dieser Baustein '
          'direkt weiter.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Bedingung hinzufügen'),
        ),
      ],
    );
  }
}

class _ConditionBranchCard extends StatelessWidget {
  const _ConditionBranchCard({
    super.key,
    required this.branch,
    required this.graph,
    required this.onConditionChanged,
    required this.onRemove,
  });

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
                    branch.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Bedingung entfernen',
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
