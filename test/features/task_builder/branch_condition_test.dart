import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';

// Deckt den neuen booleschen Ausdrucksbaum ab, der Branch-Bedingungen für
// Bedingter-Ablauf-Bausteine ohne Entscheidungs-Prompt-Vorgänger trägt.
void main() {
  test('ComparisonCondition.copyWith ändert nur die angegebenen Felder', () {
    const condition = ComparisonCondition(
      left: '{{x}}',
      operator: ComparisonOperator.equals,
      right: '10',
    );

    final updated = condition.copyWith(
      operator: ComparisonOperator.greaterThan,
    );

    expect(updated.left, '{{x}}');
    expect(updated.operator, ComparisonOperator.greaterThan);
    expect(updated.right, '10');
  });

  test('GroupCondition.copyWith ändert nur die angegebenen Felder', () {
    const child = ComparisonCondition(
      left: '{{x}}',
      operator: ComparisonOperator.equals,
      right: '1',
    );
    const group = GroupCondition(
      combinator: BooleanCombinator.and,
      children: [child],
    );

    final updated = group.copyWith(combinator: BooleanCombinator.or);

    expect(updated.combinator, BooleanCombinator.or);
    expect(updated.children, [child]);
  });

  test(
    'zwei ComparisonConditions mit gleichen Werten sind gleich (Equatable)',
    () {
      const a = ComparisonCondition(
        left: '{{x}}',
        operator: ComparisonOperator.equals,
        right: '1',
      );
      const b = ComparisonCondition(
        left: '{{x}}',
        operator: ComparisonOperator.equals,
        right: '1',
      );
      const c = ComparisonCondition(
        left: '{{x}}',
        operator: ComparisonOperator.notEquals,
        right: '1',
      );

      expect(a, b);
      expect(a, isNot(c));
    },
  );

  test('zwei GroupConditions mit gleichem Baum sind gleich (Equatable)', () {
    const child = ComparisonCondition(
      left: '{{x}}',
      operator: ComparisonOperator.equals,
      right: '1',
    );
    const a = GroupCondition(
      combinator: BooleanCombinator.and,
      children: [child],
    );
    const b = GroupCondition(
      combinator: BooleanCombinator.and,
      children: [child],
    );
    const c = GroupCondition(
      combinator: BooleanCombinator.or,
      children: [child],
    );

    expect(a, b);
    expect(a, isNot(c));
  });

  test(
    'ConditionalBranch.copyWith kann condition explizit auf null setzen',
    () {
      const branch = ConditionalBranch(
        id: 'branch.1',
        label: 'Bedingung 1',
        graph: WorkflowGraph(nodes: [], edges: []),
        condition: ComparisonCondition(
          left: '{{x}}',
          operator: ComparisonOperator.equals,
          right: '1',
        ),
      );

      final cleared = branch.copyWith(clearCondition: true);

      expect(cleared.condition, isNull);
      expect(cleared.label, 'Bedingung 1');
    },
  );

  test(
    'ConditionalBranch.copyWith ohne clearCondition behält die bestehende Bedingung',
    () {
      const condition = ComparisonCondition(
        left: '{{x}}',
        operator: ComparisonOperator.equals,
        right: '1',
      );
      const branch = ConditionalBranch(
        id: 'branch.1',
        label: 'Bedingung 1',
        graph: WorkflowGraph(nodes: [], edges: []),
        condition: condition,
      );

      final relabeled = branch.copyWith(label: 'Neu');

      expect(relabeled.condition, condition);
      expect(relabeled.label, 'Neu');
    },
  );
}
