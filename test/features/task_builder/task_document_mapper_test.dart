import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_document_mapper.dart';

void main() {
  test(
    'liest outputName rückwärtskompatibel aus dem alten referenceName-Feld',
    () {
      final mapper = TaskDocumentMapper();
      final legacyDocument = {
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
              'referenceName': 'eingang',
              'config': {'primitive': 'stringInput', 'value': ''},
            },
          ],
          'edges': [],
        },
      };

      final task = mapper.fromMap(legacyDocument, fallbackId: 'task-1');

      expect(task.nodes.single.outputName, 'eingang');
    },
  );

  test('bevorzugt outputName, wenn beide Felder im Dokument stehen', () {
    final mapper = TaskDocumentMapper();
    final document = {
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
            'outputName': 'neu',
            'referenceName': 'alt',
            'config': {'primitive': 'stringInput', 'value': ''},
          },
        ],
        'edges': [],
      },
    };

    final task = mapper.fromMap(document, fallbackId: 'task-1');

    expect(task.nodes.single.outputName, 'neu');
  });

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
