import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/local_runtime_api_client.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection_draft.dart';
import 'package:syscat2/features/language_models/infrastructure/repositories/local_language_model_repository.dart';

void main() {
  test(
    'saves and maps local language models through the runtime API',
    () async {
      final client = _RecordingClient();
      final repository = LocalLanguageModelRepository(client);

      await repository.saveLanguageModel(
        const LanguageModelDraft(
          connectionName: 'OpenAI',
          provider: LanguageModelProvider.openAiCompatible,
          baseUrl: 'https://api.openai.com/v1',
          name: 'Schnelles Modell',
          modelId: 'gpt-4.1-mini',
          apiKey: 'provider-api-key',
        ),
      );
      final models = await repository
          .watchLanguageModels(const TeamId('team-1'))
          .first;

      expect(client.postPath, '/v1/language-models');
      expect(client.postBody?['apiKey'], 'provider-api-key');
      expect(models.single.modelId, 'gpt-4.1-mini');
      expect(models.single.supportsStructuredOutput, isTrue);
    },
  );

  test('connects a provider without selecting a model', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelRepository(client);
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
}

class _RecordingClient implements LocalRuntimeApiClient {
  String? postPath;
  Map<String, Object?>? postBody;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => {
    'items': [
      {
        'id': 'model-1',
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
