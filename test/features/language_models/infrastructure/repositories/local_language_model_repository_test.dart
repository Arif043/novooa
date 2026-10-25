import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection_draft.dart';
import 'package:syscat2/features/language_models/infrastructure/repositories/local_language_model_repository.dart';

// `watchWorkspaceChannel` lädt beim ersten Listener sofort per `load()` —
// unabhängig davon, ob der Realtime-Kanal erfolgreich verbindet. Für diese
// Mapping-Tests reicht daher ein Kanal auf eine unerreichbare Adresse, mit
// einem eigenen, nicht-aufzeichnenden Client für den Ticket-Abruf — sonst
// würde dessen `POST /v1/realtime/ticket` die `postPath`/`postBody`-
// Aufzeichnung der eigentlichen `_RecordingClient`-Testdouble überschreiben.
WorkspaceRealtimeChannel _fakeChannel() =>
    WorkspaceRealtimeChannel(Uri.parse('http://127.0.0.1:0'), _NoopClient());

void main() {
  test('maps local language models from the runtime API', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client, _fakeChannel());

    final models = await repository
        .watchLanguageModels(const TeamId('team-1'))
        .first;

    expect(models.single.modelId, 'gpt-4.1-mini');
    expect(models.single.supportsStructuredOutput, isTrue);
    expect(models.single.connectionId, 'connection-1');
  });

  test('lists connected providers through the runtime API', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client, _fakeChannel());

    final connections = await repository
        .watchConnections(const TeamId('team-1'))
        .first;

    expect(connections.single.id, 'connection-1');
    expect(connections.single.name, 'Google AI');
    expect(connections.single.provider, LanguageModelProvider.googleAi);
  });

  test('removes a connection through the runtime API', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client, _fakeChannel());

    await repository.removeConnection(const TeamId('team-1'), 'connection-1');

    expect(client.deletePath, '/v1/language-model-connections/connection-1');
  });

  test('connects a provider without selecting a model', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client, _fakeChannel());
    await repository.connectLanguageModels(
      const LanguageModelConnectionDraft(
        provider: LanguageModelProvider.googleAi,
        baseUrl: '',
        apiKey: 'provider-api-key',
      ),
    );

    expect(client.postPath, '/v1/language-model-connections');
    expect(client.postBody?['provider'], 'googleAi');
    expect(client.postBody?['apiKey'], 'provider-api-key');
  });

  test('sends the fixed Mistral endpoint with the customer API key', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client, _fakeChannel());

    await repository.connectLanguageModels(
      const LanguageModelConnectionDraft(
        provider: LanguageModelProvider.mistral,
        baseUrl: 'https://api.mistral.ai/v1',
        apiKey: 'customer-api-key',
      ),
    );

    expect(client.postBody?['provider'], 'mistral');
    expect(client.postBody?['baseUrl'], 'https://api.mistral.ai/v1');
    expect(client.postBody?['apiKey'], 'customer-api-key');
  });
}

class _RecordingClient extends WorkspaceApiClient {
  String? postPath;
  Map<String, Object?>? postBody;
  String? deletePath;

  @override
  Future<Map<String, Object?>> delete(String path) async {
    deletePath = path;
    return const {};
  }

  @override
  Future<Map<String, Object?>> get(String path) async {
    if (path == '/v1/language-model-connections') {
      return {
        'items': [
          {'id': 'connection-1', 'name': 'Google AI', 'provider': 'googleAi'},
        ],
      };
    }
    return {
      'items': [
        {
          'id': 'model-1',
          'connectionId': 'connection-1',
          'name': 'Schnelles Modell',
          'modelId': 'gpt-4.1-mini',
          'capabilities': {
            'imageInput': false,
            'structuredOutput': true,
            'imageGeneration': false,
          },
        },
      ],
    };
  }

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
