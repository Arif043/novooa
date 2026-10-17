part of 'node_config.dart';

/// Vergleichsoperator einer [ComparisonCondition] — bewusst eine flache,
/// uneingeschränkte Liste im Domänenmodell: welche Operatoren für einen
/// konkreten Operanden sinnvoll sind, entscheidet die Präsentation
/// (`operatorsFor` in `branch_condition_operators.dart`), nicht die Domäne.
/// Bei Tabellen vergleichen die Zahl-Operatoren die Zeilenanzahl.
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  contains,
  notContains,
  startsWith,
  endsWith,
  isEmpty,
  isNotEmpty,
  isTrue,
  isFalse,
  sameDay,
  before,
  after,
  contentTypeIs;

  /// Einstellige Operatoren prüfen nur den linken Wert, ohne Vergleichswert.
  bool get isUnary => switch (this) {
    isEmpty || isNotEmpty || isTrue || isFalse => true,
    _ => false,
  };
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

  /// Wechselt den Operator; ein einstelliger Operator braucht keinen
  /// Vergleichswert, ein alter bliebe sonst unsichtbar gespeichert.
  ComparisonCondition withOperator(ComparisonOperator operator) {
    return ComparisonCondition(
      left: left,
      operator: operator,
      right: operator.isUnary ? '' : right,
    );
  }

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
