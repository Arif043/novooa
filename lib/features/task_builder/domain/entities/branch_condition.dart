part of 'node_config.dart';

/// Vergleichsoperator einer [ComparisonCondition] — bewusst eine flache,
/// uneingeschränkte Liste im Domänenmodell: welche Operatoren für einen
/// konkreten Operanden sinnvoll sind, entscheidet die Präsentation
/// (`operandTypeHintFor`/`operatorsFor` in
/// `branch_condition_operand_type.dart`), nicht die Domäne selbst.
enum ComparisonOperator {
  equals('ist'),
  notEquals('ist nicht'),
  greaterThan('größer als'),
  greaterThanOrEqual('größer oder gleich'),
  lessThan('kleiner als'),
  lessThanOrEqual('kleiner oder gleich'),
  contains('enthält');

  const ComparisonOperator(this.label);

  final String label;
}

/// Verknüpfung mehrerer Kind-Ausdrücke in einer [GroupCondition].
enum BooleanCombinator {
  and('UND'),
  or('ODER'),
  xor('ENTWEDER-ODER');

  const BooleanCombinator(this.label);

  final String label;
}

/// Ein boolescher Ausdrucksbaum für eine Branch-Bedingung eines
/// Bedingter-Ablauf-Bausteins ohne Entscheidungs-Prompt-Vorgänger.
/// Verschachtelung einer [GroupCondition] in einer anderen ersetzt
/// explizite Klammern — "klammern" heißt im Baukasten: einen Ausdruck in
/// eine neue Gruppe verschieben.
sealed class BranchCondition extends Equatable {
  const BranchCondition();
}

/// Ein einzelner Vergleich zweier Template-Ausdrücke (oder Literale) —
/// [left]/[right] werden zur Laufzeit über den
/// `TemplateExpressionResolver` aufgelöst (siehe
/// `branch-condition-evaluator.ts` im Backend).
class ComparisonCondition extends BranchCondition {
  const ComparisonCondition({
    required this.left,
    required this.operator,
    required this.right,
  });

  final String left;
  final ComparisonOperator operator;
  final String right;

  ComparisonCondition copyWith({
    String? left,
    ComparisonOperator? operator,
    String? right,
  }) {
    return ComparisonCondition(
      left: left ?? this.left,
      operator: operator ?? this.operator,
      right: right ?? this.right,
    );
  }

  @override
  List<Object?> get props => [left, operator, right];
}

/// Mehrere [children] verknüpft über denselben [combinator] (AND/OR/XOR).
class GroupCondition extends BranchCondition {
  const GroupCondition({required this.combinator, required this.children});

  final BooleanCombinator combinator;
  final List<BranchCondition> children;

  GroupCondition copyWith({
    BooleanCombinator? combinator,
    List<BranchCondition>? children,
  }) {
    return GroupCondition(
      combinator: combinator ?? this.combinator,
      children: children ?? this.children,
    );
  }

  @override
  List<Object?> get props => [combinator, children];
}
