import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operand_type.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operators.dart';

// Jeder typisierte Wert eines Bausteins (nicht nur Felder) bekommt seine
// passenden Vergleiche — der Typ kommt aus `outputTypeOf`.
void main() {
  final graph = WorkflowGraph(
    nodes: [
      _node('mail', const ReadEmailNodeConfig(), {
        'value': 'Mailtext',
        'receivedAt': 'Empfangen',
      }),
      _node('http', HttpRequestNodeConfig.initial(), {
        'value': 'Antwort',
        'ok': 'Erfolgreich',
        'status': 'Status',
      }),
      _node('bild', MediaInputNodeConfig.initial(), {'value': 'Bild'}),
      _node(
        'tabelle',
        const TableFromCollectionNodeConfig(collectionName: 'Kunden'),
        {'value': 'Kunden'},
      ),
    ],
    edges: const [],
  );

  OperandTypeHint hintOf(String name) => operandTypeHintFor('{{$name}}', graph);

  test('weitere Werte bekommen ihren Typ', () {
    expect(hintOf('Mailtext'), isA<StringTypeHint>());
    expect(hintOf('Empfangen'), isA<DateTimeTypeHint>());
    expect(hintOf('Erfolgreich'), isA<BooleanTypeHint>());
    expect(hintOf('Status'), isA<NumberTypeHint>());
    expect(hintOf('Antwort'), isA<JsonTypeHint>());
  });

  test('Datum vergleicht nach Tag, vor und nach', () {
    expect(operatorsFor(hintOf('Empfangen')), [
      ComparisonOperator.sameDay,
      ComparisonOperator.before,
      ComparisonOperator.after,
    ]);
  });

  test('Bild prüft Vorhandensein und Dateityp', () {
    expect(hintOf('Bild'), isA<FileTypeHint>());
    expect(operatorsFor(hintOf('Bild')), [
      ComparisonOperator.isNotEmpty,
      ComparisonOperator.isEmpty,
      ComparisonOperator.contentTypeIs,
    ]);
  });

  test('Tabelle prüft Leere und Zeilenanzahl mit einer Zahl', () {
    final hint = hintOf('Kunden');

    expect(hint, isA<TableTypeHint>());
    expect(operatorsFor(hint), contains(ComparisonOperator.greaterThan));
    expect(
      comparedValueHintFor(hint, ComparisonOperator.greaterThan),
      isA<NumberTypeHint>(),
    );
  });
}

WorkflowNode _node(String id, NodeConfig config, Map<String, String> names) {
  return WorkflowNode(
    id: NodeId(id),
    title: id,
    description: '',
    outputs: [
      for (final entry in names.entries)
        WorkflowOutput(key: entry.key, name: entry.value, showOnCanvas: true),
    ],
    config: config,
  );
}
