import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

/// Lesbarer Text einer Zweig-Bedingung für die Leinwand, z.B.
/// „Antwort ist Ja“; ein Zweig ohne Bedingung ist „Sonst“.
String branchConditionSummary(BranchCondition? condition) {
  return switch (condition) {
    null => LocaleKeys.ui_sonst.tr(),
    final ComparisonCondition comparison => _comparisonText(comparison),
    final GroupCondition group => _groupText(group),
  };
}

extension ComparisonOperatorText on ComparisonOperator {
  String get localizedLabel => switch (this) {
    ComparisonOperator.equals => LocaleKeys.task_builder_operators_equals.tr(),
    ComparisonOperator.notEquals =>
      LocaleKeys.task_builder_operators_notEquals.tr(),
    ComparisonOperator.greaterThan =>
      LocaleKeys.task_builder_operators_greaterThan.tr(),
    ComparisonOperator.greaterThanOrEqual =>
      LocaleKeys.task_builder_operators_greaterThanOrEqual.tr(),
    ComparisonOperator.lessThan =>
      LocaleKeys.task_builder_operators_lessThan.tr(),
    ComparisonOperator.lessThanOrEqual =>
      LocaleKeys.task_builder_operators_lessThanOrEqual.tr(),
    ComparisonOperator.contains =>
      LocaleKeys.task_builder_operators_contains.tr(),
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

String _comparisonText(ComparisonCondition condition) {
  return [
    _operandText(condition.left),
    condition.operator.localizedLabel,
    _operandText(condition.right),
  ].join(' ');
}

String _groupText(GroupCondition group) {
  return group.children
      .map(
        (child) => switch (child) {
          final GroupCondition nested => '(${_groupText(nested)})',
          final ComparisonCondition comparison => _comparisonText(comparison),
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
