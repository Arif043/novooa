import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_import.dart';
import 'package:syscat2/features/machine_learning/infrastructure/repositories/local_model_catalog_repository.dart';

void main() {
  test('maps local catalog entries and imports an ONNX artifact', () async {
    final client = _Client();
    // Ein eigener, nicht-aufzeichnender Client für den Ticket-Abruf — sonst
    // würde dessen `POST /v1/realtime/ticket` die `postPath`/`postBody`-
    // Aufzeichnung von `_Client` durcheinanderbringen.
    final channel = WorkspaceRealtimeChannel(
      Uri.parse('http://127.0.0.1:0'),
      _NoopClient(),
    );
    final repository = LocalModelCatalogRepository(client, channel);

    final entries = await repository.watchEntries().first;
    await repository.importEntry(
      ModelCatalogImport(
        manifestJson: '{"id":"model","title":"Modell"}',
        artifactLength: 3,
        openArtifact: () => Stream.value([1, 2, 3]),
      ),
    );

    expect(entries.single.title, 'Beispielmodell');
    expect(entries.single.inputs.single.name, 'image');
    expect(entries.single.outputs.single.workflowName, 'classifications');
    expect(entries.single.outputs.single.workflowType, 'json');
    expect(entries.single.outputs.single.parameters.single.defaultValue, 3);
    expect(entries.single.isManagedLocally, isTrue);
    expect(client.postPath, '/v1/ml-models/imports');
    expect(client.postBody, {
      'manifest': {'id': 'model', 'title': 'Modell'},
    });
    expect(client.uploadPath, '/v1/ml-models/imports/upload-1/artifact');
    expect(client.uploadLength, 3);
    expect(client.uploadContentType, 'application/onnx');
    expect(client.uploadedBytes, [1, 2, 3]);
  });
}

class _Client extends WorkspaceApiClient {
  String? postPath;
  Map<String, Object?>? postBody;
  String? uploadPath;
  int? uploadLength;
  String? uploadContentType;
  List<int> uploadedBytes = [];

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
              'transformations': [
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
    return const {'importId': 'upload-1'};
  }

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) async {
    uploadPath = path;
    uploadLength = contentLength;
    uploadContentType = contentType;
    uploadedBytes = await body.expand((chunk) => chunk).toList();
    return const {};
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}

class _NoopClient extends WorkspaceApiClient {
  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
