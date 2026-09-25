import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import 'branch_condition_editor.dart';
import 'branch_condition_operand_type.dart';

/// Eine einzelne Vergleichszeile (Blatt eines [BranchCondition]-Baums):
/// zwei Template-/Literal-Felder, dazwischen der Operator-Chip
/// ([_OperatorChip]) und rechts entweder Freitext oder — bei einem
/// erkannten [EnumTypeHint] (z.B. Entscheidungs-Choices, Dialogeingabe
/// Auswahl/Radio) — eine feste Werteliste ([_EnumValueField]).
class ComparisonRow extends StatelessWidget {
  const ComparisonRow({
    super.key,
    required this.comparison,
    required this.graph,
    required this.onChanged,
    required this.onRemove,
    required this.onGroup,
  });

  final ComparisonCondition comparison;
  final WorkflowGraph graph;
  final ValueChanged<BranchCondition> onChanged;
  final VoidCallback? onRemove;
  final ValueChanged<BooleanCombinator> onGroup;

  @override
  Widget build(BuildContext context) {
    // Zwei Zeilen statt einer einzigen breiten Row: der Operator-Chip kann
    // je nach Datentyp lange Labels tragen (z.B. "größer oder gleich"),
    // zusammen mit zwei Text-/Dropdown-Feldern und bis zu drei Icon-Buttons
    // hätte eine einzelne Row auf schmalen Bildschirmen (und selbst bei
    // Standardbreite) überlaufen können.
    final hint = operandTypeHintFor(comparison.left, graph);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: comparison.left,
                  decoration: const InputDecoration(hintText: '{{baustein.value}}'),
                  onChanged: (value) => onChanged(comparison.copyWith(left: value)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _OperatorChip(
                operator: comparison.operator,
                options: operatorsFor(hint),
                onSelected: (operator) =>
                    onChanged(comparison.copyWith(operator: operator)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: switch (hint) {
                  EnumTypeHint(:final values) => _EnumValueField(
                    values: values,
                    value: comparison.right,
                    onChanged: (value) =>
                        onChanged(comparison.copyWith(right: value)),
                  ),
                  _ => TextFormField(
                    initialValue: comparison.right,
                    decoration: const InputDecoration(hintText: 'Wert oder {{...}}'),
                    onChanged: (value) =>
                        onChanged(comparison.copyWith(right: value)),
                  ),
                },
              ),
              GroupMenuButton(onSelected: onGroup),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Bedingung entfernen',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Zeigt den aktuellen Operator als Label; Klick öffnet ein Dropdown mit
/// den zum erkannten Operanden-Datentyp passenden Operatoren
/// ([operatorsFor]) — der Auftrag verlangt explizit dieses
/// Label-mit-Klick-Muster statt Dialog oder dauerhaft sichtbarer Liste.
class _OperatorChip extends StatelessWidget {
  const _OperatorChip({
    required this.operator,
    required this.options,
    required this.onSelected,
  });

  final ComparisonOperator operator;
  final List<ComparisonOperator> options;
  final ValueChanged<ComparisonOperator> onSelected;

  @override
  Widget build(BuildContext context) {
    final shown = options.contains(operator) ? operator : options.first;
    return PopupMenuButton<ComparisonOperator>(
      tooltip: 'Operator wählen',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Chip(label: Text(shown.label)),
      ),
    );
  }
}

class _EnumValueField extends StatelessWidget {
  const _EnumValueField({
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final List<String> values;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: values.contains(value) ? value : null,
      decoration: const InputDecoration(hintText: 'Wert wählen'),
      items: [
        for (final option in values) DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
