import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_cache_status.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
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

    expect(entries.single.title, 'Sample model');
    expect(entries.single.titleFor('de-DE'), 'Beispielmodell');
    expect(entries.single.descriptionFor('de'), 'Klassifiziert Testdaten.');
    expect(entries.single.tagsFor('de'), ['testen']);
    expect(entries.single.titleFor('fr'), 'Sample model');
    expect(entries.single.tagsFor('fr'), ['test']);
    expect(entries.single.inputs.single.name, 'image');
    expect(entries.single.outputs.single.workflowName, 'classifications');
    expect(entries.single.outputs.single.workflowType, 'json');
    expect(entries.single.isManagedLocally, isTrue);
    // Ohne `origin` (ältere Runtime) gilt ein Teameintrag als eigener Import.
    expect(entries.single.origin, ModelOrigin.import);
    expect(entries.single.task, ModelTask.imageClassification);
    expect(entries.single.languages, ['de', 'en']);
    expect(client.postPath, '/v1/ml-models/imports');
    expect(client.postBody, {
      'manifest': {'id': 'model', 'title': 'Modell'},
    });
    expect(client.uploadPath, '/v1/ml-models/imports/upload-1/artifact');
    expect(client.uploadLength, 3);
    expect(client.uploadContentType, 'application/onnx');
    expect(client.uploadedBytes, [1, 2, 3]);
  });

  test('maps an image workflow output and labels it as Bild', () async {
    final repository = LocalModelCatalogRepository(_ImageClient(), _channel());

    final output = (await repository.loadGlobalEntries()).single.outputs.single;

    expect(output.workflowType, 'image');
    expect(output.workflowTypeLabel, 'Bild');
  });

  test('maps an audio workflow output from the global catalog', () async {
    final repository = LocalModelCatalogRepository(_AudioClient(), _channel());

    final entries = await repository.loadGlobalEntries();

    expect(entries.single.outputs.single.workflowType, 'audio');
    expect(entries.single.origin, isNull);
    // Einträge ohne Aufgabe (ältere Kataloge) gelten als „Sonstige“.
    expect(entries.single.task, ModelTask.other);
    expect(entries.single.languages, isEmpty);
  });

  test('starts a background download and maps the cache status', () async {
    final client = _CacheClient();
    final repository = LocalModelCatalogRepository(client, _channel());

    await repository.cacheGlobalEntry('whisper base');
    final statuses = await repository.watchCacheStatuses().first;

    expect(client.postPath, '/v1/ml-models/catalog/whisper%20base/cache');
    expect(statuses, const [
      ModelCacheStatus(modelId: 'a', state: ModelCacheState.downloading),
      ModelCacheStatus(
        modelId: 'b',
        state: ModelCacheState.failed,
        message: 'Netzwerkfehler.',
      ),
    ]);
  });
}

class _CacheClient extends _Client {
  @override
  Future<Map<String, Object?>> get(String path) async => {
    'items': [
      {'modelId': 'a', 'state': 'downloading'},
      {'modelId': 'b', 'state': 'failed', 'message': 'Netzwerkfehler.'},
    ],
  };
}

WorkspaceRealtimeChannel _channel() =>
    WorkspaceRealtimeChannel(Uri.parse('http://127.0.0.1:0'), _NoopClient());

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
        'title': 'Sample model',
        'description': 'Classifies test data.',
        'translations': {
          'de': {
            'title': 'Beispielmodell',
            'description': 'Klassifiziert Testdaten.',
            'tags': ['testen'],
          },
        },
        'task': 'image-classification',
        'languages': ['de', 'en'],
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

class _ImageClient extends _AudioClient {
  @override
  Future<Map<String, Object?>> get(String path) async {
    final body = await super.get(path);
    final entry = (body['items']! as List).single as Map<String, Object?>;
    final contract = entry['contract']! as Map<String, Object?>;
    final output = (contract['outputs']! as List).single as Map<String, Object?>;
    (output['workflowOutput']! as Map<String, Object?>)['type'] = 'image';
    return body;
  }
}

class _AudioClient extends _Client {
  @override
  Future<Map<String, Object?>> get(String path) async => {
    'items': [
      {
        'id': 'speech-model',
        'title': 'Sprachmodell',
        'description': 'Erzeugt Audio.',
        'tags': ['sprache'],
        'scope': {'type': 'system'},
        'artifactReference': {'sizeBytes': 1024},
        'contract': {
          'inputs': [],
          'outputs': [
            {
              'name': 'audio',
              'semantic': 'speech.audio',
              'workflowOutput': {
                'name': 'audio',
                'type': 'audio',
                'mapping': r'$tensor',
              },
              'transformations': [],
            },
          ],
        },
      },
    ],
  };
}
