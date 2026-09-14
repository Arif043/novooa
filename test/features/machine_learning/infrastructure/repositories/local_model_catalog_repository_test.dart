import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_import.dart';
import 'package:syscat2/features/machine_learning/infrastructure/repositories/local_model_catalog_repository.dart';

void main() {
  test('maps local catalog entries and imports an ONNX artifact', () async {
    final client = _Client();
    final repository = LocalModelCatalogRepository(client);

    final entries = await repository.watchEntries().first;
    await repository.importEntry(
      const ModelCatalogImport(
        manifestJson: '{"id":"model","title":"Modell"}',
        artifactBytes: [1, 2, 3],
      ),
    );

    expect(entries.single.title, 'Beispielmodell');
    expect(entries.single.inputs.single.name, 'image');
    expect(entries.single.outputs.single.workflowName, 'classifications');
    expect(entries.single.outputs.single.workflowType, 'json');
    expect(entries.single.outputs.single.parameters.single.defaultValue, 3);
    expect(entries.single.isManagedLocally, isTrue);
    expect(client.postPath, '/v1/ml-models');
    expect(client.postBody?['artifactBase64'], base64Encode([1, 2, 3]));
  });
}

class _Client implements WorkspaceApiClient {
  String? postPath;
  Map<String, Object?>? postBody;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => {
    'items': [
      {
        'id': 'model-1',
        'title': 'Beispielmodell',
        'description': 'Klassifiziert Testdaten.',
        'tags': ['test'],
        'scope': {'type': 'team', 'teamId': 'local-team'},
        'artifactReference': {'sizeBytes': 1024},
        'contract': {
          'inputs': [
            {
              'name': 'image',
              'source': 'image',
              'dataType': 'float32',
              'shape': [1, 3, 224, 224],
            },
          ],
          'outputs': [
            {
              'name': 'scores',
              'semantic': 'classification.scores',
              'workflowOutput': {
                'name': 'classifications',
                'type': 'json',
                'mapping': {'classes': {}},
              },
              'postprocessing': [
                {
                  'type': 'tensor.topK',
                  'result': 'topClasses',
                  'parameters': {
                    'parameter': {
                      'name': 'k',
                      'label': 'Anzahl der Ergebnisse',
                      'default': 3,
                      'minimum': 1,
                      'maximum': 20,
                    },
                  },
                },
              ],
            },
          ],
        },
      },
    ],
  };

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    postPath = path;
    postBody = body;
    return const {};
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
