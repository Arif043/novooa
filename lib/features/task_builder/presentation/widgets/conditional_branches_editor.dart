import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import 'branch_condition_editor.dart';

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
        ? state.editingTask.graph
        : WorkflowGraph.empty();
    final cubit = context.read<TaskBuilderCubit>();
    final conditioned = _config.branches
        .where((branch) => branch.condition != null)
        .toList();
    final sonst = _config.branches.where((branch) => branch.condition == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wenn', style: SyscatTheme.taskBody),
        const SizedBox(height: AppSpacing.sm),
        if (conditioned.isEmpty)
          _EmptyBranchesNotice(onAdd: () => cubit.addConditionBranch(node.id))
        else ...[
          for (final branch in conditioned)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ConditionBranchCard(
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
          for (final branch in sonst) _SonstBranchRow(branch: branch),
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
          style: SyscatTheme.taskBodySmall,
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
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

class _SonstBranchRow extends StatelessWidget {
  const _SonstBranchRow({required this.branch});

  final ConditionalBranch branch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.arrow_forward,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${branch.label}: greift, wenn keine Bedingung oben zutrifft.',
            style: SyscatTheme.taskBodySmall,
          ),
        ),
      ],
    );
  }
}
