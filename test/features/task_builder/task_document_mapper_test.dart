import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_document_mapper.dart';

Map<String, Object?> _taskWithNode(Map<String, Object?> node) => {
  'id': 'task-1',
  'title': 'Aufgabe',
  'objective': '',
  'selectedNodeId': 'node-1',
  'graph': {
    'nodes': [node],
    'edges': [],
  },
};

void main() {
  test('speichert die benannten Werte samt Leinwand-Flag hin und zurück', () {
    final mapper = TaskDocumentMapper();
    final task = mapper.fromMap(
      mapper.toDocument(
        mapper.fromMap(
          _taskWithNode({
            'id': 'node-1',
            'title': 'Suche',
            'description': '',
            'outputs': [
              {'key': 'value', 'name': 'Datensatz', 'showOnCanvas': true},
              {'key': 'found', 'name': 'Gefunden', 'showOnCanvas': false},
              {'key': 'kaputt'},
            ],
            'config': {'primitive': 'stringInput', 'value': ''},
          }),
          fallbackId: 'task-1',
        ),
      ),
      fallbackId: 'task-1',
    );

    expect(task.nodes.single.outputs, const [
      WorkflowOutput.primary('Datensatz'),
      WorkflowOutput(key: 'found', name: 'Gefunden'),
    ]);
  });

  test('liest kein altes outputName mehr', () {
    final mapper = TaskDocumentMapper();
    final task = mapper.fromMap(
      _taskWithNode({
        'id': 'node-1',
        'title': 'Text',
        'description': '',
        'outputName': 'eingang',
        'config': {'primitive': 'stringInput', 'value': ''},
      }),
      fallbackId: 'task-1',
    );

    expect(task.nodes.single.outputs, isEmpty);
  });
}
