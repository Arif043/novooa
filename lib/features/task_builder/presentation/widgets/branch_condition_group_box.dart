import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import 'branch_condition_editor.dart';

/// Eine [GroupCondition] als eingerückter Rahmen: Verknüpfungs-Auswahl
/// (AND/OR/XOR) oben, darunter rekursiv jedes Kind über
/// [BranchConditionEditor] — Verschachtelung IST die Klammerung, kein
/// separates Klammer-Widget nötig.
class GroupBox extends StatelessWidget {
  const GroupBox({
    super.key,
    required this.group,
    required this.graph,
    required this.onChanged,
    required this.onRemove,
    required this.onGroup,
  });

  final GroupCondition group;
  final WorkflowGraph graph;
  final ValueChanged<BranchCondition> onChanged;
  final VoidCallback? onRemove;
  final ValueChanged<BooleanCombinator> onGroup;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(
              group: group,
              onChanged: onChanged,
              onRemove: onRemove,
              onGroup: onGroup,
            ),
            for (var index = 0; index < group.children.length; index++)
              BranchConditionEditor(
                condition: group.children[index],
                graph: graph,
                onChanged: (child) => onChanged(_replacedChild(index, child)),
                onRemove: group.children.length > 1
                    ? () => onChanged(_removedChild(index))
                    : null,
              ),
            TextButton.icon(
              onPressed: () => onChanged(
                group.copyWith(
                  children: [...group.children, emptyComparisonCondition],
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Bedingung'),
            ),
          ],
        ),
      ),
    );
  }

  BranchCondition _replacedChild(int index, BranchCondition child) {
    final children = [...group.children]..[index] = child;
    return group.copyWith(children: children);
  }

  BranchCondition _removedChild(int index) {
    final children = [...group.children]..removeAt(index);
    return group.copyWith(children: children);
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.onChanged,
    required this.onRemove,
    required this.onGroup,
  });

  final GroupCondition group;
  final ValueChanged<BranchCondition> onChanged;
  final VoidCallback? onRemove;
  final ValueChanged<BooleanCombinator> onGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // `Flexible` statt einer festen Breite + `isExpanded: true`: das
        // längste Label ("ENTWEDER-ODER") ist breiter als ein
        // fest-dimensionierter SizedBox — ohne `isExpanded` sizt sich das
        // Dropdown intern am Inhalt und lief über statt zu ellipsieren.
        Flexible(
          child: DropdownButtonFormField<BooleanCombinator>(
            isExpanded: true,
            initialValue: group.combinator,
            decoration: const InputDecoration(labelText: 'Verknüpfung'),
            items: [
              for (final combinator in BooleanCombinator.values)
                DropdownMenuItem(value: combinator, child: Text(combinator.label)),
            ],
            onChanged: (combinator) {
              if (combinator != null) {
                onChanged(group.copyWith(combinator: combinator));
              }
            },
          ),
        ),
        const Spacer(),
        GroupMenuButton(onSelected: onGroup),
        if (onRemove != null)
          IconButton(
            tooltip: 'Gruppe entfernen',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
      ],
    );
  }
}
