import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_summary.dart';

const _antwortIstJa = ComparisonCondition(
  left: '{{Antwort}}',
  operator: ComparisonOperator.equals,
  right: 'Ja',
);

final _graph = WorkflowGraph.empty();

void main() {
  test('ein Vergleich zeigt Wertname, Operator und festen Wert', () {
    expect(branchConditionSummary(_antwortIstJa, _graph), 'Antwort ist Ja');
  });

  test('ein Verweis rechts wird wie links ohne Klammern gezeigt', () {
    const condition = ComparisonCondition(
      left: '{{Summe}}',
      operator: ComparisonOperator.greaterThan,
      right: '{{Grenze}}',
    );

    expect(
      branchConditionSummary(condition, _graph),
      'Summe größer als Grenze',
    );
  });

  test('leere Operanden erscheinen als Auslassung', () {
    const condition = ComparisonCondition(
      left: '',
      operator: ComparisonOperator.equals,
      right: ' ',
    );

    expect(branchConditionSummary(condition, _graph), '… ist …');
  });

  test(
    'Gruppen werden mit Bindewort verbunden, verschachtelte in Klammern',
    () {
      const condition = GroupCondition(
        combinator: BooleanCombinator.and,
        children: [
          _antwortIstJa,
          GroupCondition(
            combinator: BooleanCombinator.or,
            children: [
              ComparisonCondition(
                left: '{{Land}}',
                operator: ComparisonOperator.contains,
                right: 'DE',
              ),
              ComparisonCondition(
                left: '{{Land}}',
                operator: ComparisonOperator.notEquals,
                right: 'AT',
              ),
            ],
          ),
        ],
      );

      expect(
        branchConditionSummary(condition, _graph),
        'Antwort ist Ja und (Land enthält DE oder Land ist nicht AT)',
      );
    },
  );

  test('ein Zweig ohne Bedingung heißt „Sonst“', () {
    expect(branchConditionSummary(null, _graph), 'Sonst');
  });

  test('einstellige Operatoren zeigen keinen Vergleichswert', () {
    const condition = ComparisonCondition(
      left: '{{Bezahlt}}',
      operator: ComparisonOperator.isTrue,
      right: '',
    );

    expect(branchConditionSummary(condition, _graph), 'Bezahlt ist wahr');
  });

  test('Bilder und Tabellen haben eigene Formulierungen', () {
    final graph = WorkflowGraph(
      nodes: [
        const WorkflowNode(
          id: NodeId('bild'),
          title: 'Bild',
          description: '',
          outputs: [WorkflowOutput(key: 'Scan', name: 'Scan')],
          config: DialogInputNodeConfig(
            instruction: '',
            fields: [
              DialogInputField(name: 'Scan', type: DialogInputFieldType.image),
            ],
          ),
        ),
        const WorkflowNode(
          id: NodeId('tabelle'),
          title: 'Tabelle',
          description: '',
          outputs: [WorkflowOutput.primary('Kunden')],
          config: TableFromCollectionNodeConfig(collectionName: 'Kunden'),
        ),
      ],
      edges: const [],
    );
    String summary(String left, ComparisonOperator operator, String right) {
      final condition = ComparisonCondition(
        left: left,
        operator: operator,
        right: right,
      );
      return branchConditionSummary(condition, graph);
    }

    expect(summary('{{Scan}}', ComparisonOperator.isEmpty, ''), 'Scan fehlt');
    expect(
      summary('{{Kunden}}', ComparisonOperator.greaterThan, '3'),
      'Kunden hat mehr als 3 Zeilen',
    );
  });
}
