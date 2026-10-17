import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

import 'branch_condition_operand_type.dart';

extension ComparisonOperatorText on ComparisonOperator {
  String get localizedLabel => switch (this) {
    ComparisonOperator.equals => LocaleKeys.task_builder_operators_equals,
    ComparisonOperator.notEquals => LocaleKeys.task_builder_operators_notEquals,
    ComparisonOperator.greaterThan =>
      LocaleKeys.task_builder_operators_greaterThan,
    ComparisonOperator.greaterThanOrEqual =>
      LocaleKeys.task_builder_operators_greaterThanOrEqual,
    ComparisonOperator.lessThan => LocaleKeys.task_builder_operators_lessThan,
    ComparisonOperator.lessThanOrEqual =>
      LocaleKeys.task_builder_operators_lessThanOrEqual,
    ComparisonOperator.contains => LocaleKeys.task_builder_operators_contains,
    ComparisonOperator.notContains =>
      LocaleKeys.task_builder_operators_notContains,
    ComparisonOperator.startsWith =>
      LocaleKeys.task_builder_operators_startsWith,
    ComparisonOperator.endsWith => LocaleKeys.task_builder_operators_endsWith,
    ComparisonOperator.isEmpty => LocaleKeys.task_builder_operators_isEmpty,
    ComparisonOperator.isNotEmpty =>
      LocaleKeys.task_builder_operators_isNotEmpty,
    ComparisonOperator.isTrue => LocaleKeys.task_builder_operators_isTrue,
    ComparisonOperator.isFalse => LocaleKeys.task_builder_operators_isFalse,
    ComparisonOperator.sameDay => LocaleKeys.task_builder_operators_sameDay,
    ComparisonOperator.before => LocaleKeys.task_builder_operators_before,
    ComparisonOperator.after => LocaleKeys.task_builder_operators_after,
    ComparisonOperator.contentTypeIs =>
      LocaleKeys.task_builder_operators_contentTypeIs,
  }.tr();
}

/// Beschriftung im Auswahlfeld; bei Tabellen mit Platzhalter für die Zahl
/// („hat mehr als … Zeilen“).
String operatorLabelFor(ComparisonOperator operator, OperandTypeHint hint) {
  return _typedPhrase(operator, hint, '…') ?? operator.localizedLabel;
}

/// Operator samt Vergleichswert, wie er in einem Satz steht: „ist vor
/// 2026-01-01“, „hat mehr als 3 Zeilen“, „fehlt“.
String comparisonPhraseFor(
  ComparisonOperator operator,
  OperandTypeHint hint,
  String comparedValue,
) {
  final typed = _typedPhrase(operator, hint, comparedValue);
  if (typed != null) return typed;
  if (operator.isUnary) return operator.localizedLabel;
  return '${operator.localizedLabel} $comparedValue';
}

String? _typedPhrase(
  ComparisonOperator operator,
  OperandTypeHint hint,
  String comparedValue,
) {
  return switch ((hint, operator)) {
    (FileTypeHint(), ComparisonOperator.isEmpty) =>
      LocaleKeys.task_builder_file_operators_isEmpty.tr(),
    (FileTypeHint(), ComparisonOperator.isNotEmpty) =>
      LocaleKeys.task_builder_file_operators_isNotEmpty.tr(),
    (TableTypeHint(), _) => _rowCountKey(operator)?.tr(args: [comparedValue]),
    _ => null,
  };
}

String? _rowCountKey(ComparisonOperator operator) {
  return switch (operator) {
    ComparisonOperator.equals => LocaleKeys.task_builder_table_operators_equals,
    ComparisonOperator.notEquals =>
      LocaleKeys.task_builder_table_operators_notEquals,
    ComparisonOperator.greaterThan =>
      LocaleKeys.task_builder_table_operators_greaterThan,
    ComparisonOperator.greaterThanOrEqual =>
      LocaleKeys.task_builder_table_operators_greaterThanOrEqual,
    ComparisonOperator.lessThan =>
      LocaleKeys.task_builder_table_operators_lessThan,
    ComparisonOperator.lessThanOrEqual =>
      LocaleKeys.task_builder_table_operators_lessThanOrEqual,
    _ => null,
  };
}
