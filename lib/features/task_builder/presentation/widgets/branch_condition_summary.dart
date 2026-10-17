import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';

import 'branch_condition_operand_type.dart';
import 'branch_condition_operator_labels.dart';

export 'branch_condition_operator_labels.dart' show ComparisonOperatorText;

/// Lesbarer Text einer Zweig-Bedingung für die Leinwand, z.B.
/// „Antwort ist Ja“ oder „Kunden hat mehr als 3 Zeilen“; ein Zweig ohne
/// Bedingung ist „Sonst“. [graph] bestimmt die Typen der Werte.
String branchConditionSummary(BranchCondition? condition, WorkflowGraph graph) {
  return switch (condition) {
    null => LocaleKeys.ui_sonst.tr(),
    final ComparisonCondition comparison => _comparisonText(comparison, graph),
    final GroupCondition group => _groupText(group, graph),
  };
}

extension BooleanCombinatorText on BooleanCombinator {
  /// Das Bindewort zwischen zwei Bedingungen („und“, „oder“ …).
  String get conjunction => switch (this) {
    BooleanCombinator.and => LocaleKeys.task_builder_combinators_and.tr(),
    BooleanCombinator.or => LocaleKeys.task_builder_combinators_or.tr(),
    BooleanCombinator.xor => LocaleKeys.task_builder_combinators_xor.tr(),
  };
}

String _comparisonText(ComparisonCondition condition, WorkflowGraph graph) {
  final hint = operandTypeHintFor(condition.left, graph);
  final phrase = comparisonPhraseFor(
    condition.operator,
    hint,
    _operandText(condition.right),
  );
  return '${_operandText(condition.left)} $phrase';
}

String _groupText(GroupCondition group, WorkflowGraph graph) {
  return group.children
      .map(
        (child) => switch (child) {
          final GroupCondition nested => '(${_groupText(nested, graph)})',
          final ComparisonCondition comparison => _comparisonText(
            comparison,
            graph,
          ),
        },
      )
      .join(' ${group.combinator.conjunction} ');
}

/// `{{Antwort}}` wird zu „Antwort“; ein leerer Operand zu „…“.
String _operandText(String operand) {
  final text = operand
      .replaceAllMapped(_reference, (match) => match.group(1)!)
      .trim();
  return text.isEmpty ? '…' : text;
}

final _reference = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');
