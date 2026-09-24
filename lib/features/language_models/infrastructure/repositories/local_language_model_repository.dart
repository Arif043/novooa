import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_connection_draft.dart';
import '../../domain/entities/language_model_draft.dart';
import '../../domain/repositories/language_model_connection_repository.dart';
import '../../domain/repositories/language_model_repository.dart';

class LocalLanguageModelRepository
    implements LanguageModelRepository, LanguageModelConnectionRepository {
  const LocalLanguageModelRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Future<void> connectLanguageModels(LanguageModelConnectionDraft draft) async {
    await _client.post('/v1/language-model-connections', {
      'provider': draft.provider.id,
      if (draft.provider != LanguageModelProvider.googleAi)
        'baseUrl': draft.baseUrl,
      'apiKey': draft.apiKey,
    });
  }

  @override
  Future<void> saveLanguageModel(LanguageModelDraft draft) async {
    await _client.post('/v1/language-models', {
      'connectionName': draft.connectionName,
      'provider': draft.provider.id,
      if (draft.provider != LanguageModelProvider.googleAi)
        'baseUrl': draft.baseUrl,
      'name': draft.name,
      'languageModelId': draft.modelId,
      'apiKey': draft.apiKey,
    });
  }

  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) {
    return watchWorkspaceChannel('language-models', _load, _channel);
  }

  Future<List<LanguageModel>> _load() async {
    final response = await _client.get('/v1/language-models');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException(
        'Sprachmodelle konnten nicht gelesen werden.',
      );
    }
    return items.map(_modelFrom).toList(growable: false);
  }

  LanguageModel _modelFrom(Object? value) {
    if (value is! Map) {
      throw const FormatException('Sprachmodell ist ungültig.');
    }
    final model = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    final capabilities = model['capabilities'];
    if (capabilities is! Map) {
      throw const FormatException('Sprachmodell ist ungültig.');
    }
    return LanguageModel(
      id: _text(model, 'id'),
      name: _text(model, 'name'),
      modelId: _text(model, 'modelId'),
      supportsImageInput: capabilities['imageInput'] == true,
      supportsStructuredOutput: capabilities['structuredOutput'] == true,
      supportsImageGeneration: capabilities['imageGeneration'] == true,
    );
  }

  String _text(Map<String, Object?> model, String field) {
    final value = model[field];
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException('Sprachmodell ist ungültig.');
  }
}
