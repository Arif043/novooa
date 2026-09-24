import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_document_mapper.dart';

void main() {
  test('rundet outputName unter dem neuen Schlüssel', () {
    final mapper = TaskDocumentMapper();
    final task = mapper.fromMap(
      mapper.toDocument(
        mapper.fromMap({
          'id': 'task-1',
          'title': 'Aufgabe',
          'objective': '',
          'selectedNodeId': 'node-1',
          'graph': {
            'nodes': [
              {
                'id': 'node-1',
                'title': 'Text',
                'description': '',
                'outputName': 'eingang',
                'config': {'primitive': 'stringInput', 'value': ''},
              },
            ],
            'edges': [],
          },
        }, fallbackId: 'task-1'),
      ),
      fallbackId: 'task-1',
    );

    expect(task.nodes.single.outputName, 'eingang');
  });
}
