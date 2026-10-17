import '../../domain/entities/node_config.dart';
import 'branch_condition_operand_type.dart';

const _numberOperators = [
  ComparisonOperator.equals,
  ComparisonOperator.notEquals,
  ComparisonOperator.greaterThan,
  ComparisonOperator.greaterThanOrEqual,
  ComparisonOperator.lessThan,
  ComparisonOperator.lessThanOrEqual,
];

/// Die Vergleiche, die für einen Wert dieses Typs sinnvoll sind. Ohne
/// erkennbaren Typ bleiben die allgemeinen Vergleiche.
List<ComparisonOperator> operatorsFor(OperandTypeHint hint) {
  return switch (hint) {
    StringTypeHint() => const [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
      ComparisonOperator.contains,
      ComparisonOperator.notContains,
      ComparisonOperator.startsWith,
      ComparisonOperator.endsWith,
      ComparisonOperator.isEmpty,
      ComparisonOperator.isNotEmpty,
    ],
    NumberTypeHint() => _numberOperators,
    BooleanTypeHint() => const [
      ComparisonOperator.isTrue,
      ComparisonOperator.isFalse,
    ],
    EnumTypeHint() => const [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
    ],
    DateTimeTypeHint() => const [
      ComparisonOperator.sameDay,
      ComparisonOperator.before,
      ComparisonOperator.after,
    ],
    JsonTypeHint() => const [
      ComparisonOperator.contains,
      ComparisonOperator.isEmpty,
      ComparisonOperator.isNotEmpty,
    ],
    FileTypeHint() => const [
      ComparisonOperator.isNotEmpty,
      ComparisonOperator.isEmpty,
      ComparisonOperator.contentTypeIs,
    ],
    TableTypeHint() => const [
      ComparisonOperator.isEmpty,
      ComparisonOperator.isNotEmpty,
      ..._numberOperators,
    ],
    UnknownTypeHint() => const [
      ..._numberOperators,
      ComparisonOperator.contains,
    ],
  };
}

/// Welche Art Wert der Vergleichswert ist: Bei Tabellen ist es die
/// Zeilenanzahl, sonst derselbe Typ wie der geprüfte Wert.
OperandTypeHint comparedValueHintFor(
  OperandTypeHint hint,
  ComparisonOperator operator,
) {
  return switch (hint) {
    TableTypeHint() => const NumberTypeHint(),
    FileTypeHint() when operator == ComparisonOperator.contentTypeIs =>
      const StringTypeHint(),
    _ => hint,
  };
}
