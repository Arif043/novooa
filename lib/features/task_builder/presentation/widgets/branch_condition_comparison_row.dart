import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import 'branch_condition_editor.dart';
import 'branch_condition_operand_type.dart';
import 'condition_value_field.dart';
import 'branch_condition_summary.dart';

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
    final hint = operandTypeHintFor(comparison.left, graph);
    final operators = {...operatorsFor(hint), comparison.operator};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConditionValueField(
            label: LocaleKeys.ui_wert_pruefen.tr(),
            value: comparison.left,
            graph: graph,
            preferSource: true,
            onChanged: (value) {
              final allowed = operatorsFor(operandTypeHintFor(value, graph));
              onChanged(
                comparison.copyWith(
                  left: value,
                  operator: allowed.contains(comparison.operator)
                      ? comparison.operator
                      : ComparisonOperator.equals,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ComparisonOperator>(
            key: ValueKey(comparison.operator),
            isExpanded: true,
            initialValue: comparison.operator,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_vergleich.tr(),
            ),
            items: [
              for (final operator in operators)
                DropdownMenuItem(
                  value: operator,
                  child: Text(operator.localizedLabel),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(comparison.copyWith(operator: value));
              }
            },
          ),
          const SizedBox(height: 8),
          ConditionValueField(
            label: LocaleKeys.ui_vergleichswert.tr(),
            value: comparison.right,
            graph: graph,
            hint: hint,
            onChanged: (value) => onChanged(comparison.copyWith(right: value)),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              GroupMenuButton(onSelected: onGroup),
              if (onRemove != null)
                IconButton(
                  tooltip: LocaleKeys.ui_bedingung_entfernen.tr(),
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
