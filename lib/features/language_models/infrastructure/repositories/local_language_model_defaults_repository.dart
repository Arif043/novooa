import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model_defaults.dart';
import '../../domain/repositories/language_model_defaults_repository.dart';

class LocalLanguageModelDefaultsRepository
    implements LanguageModelDefaultsRepository {
  const LocalLanguageModelDefaultsRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<LanguageModelDefaults> watchLanguageModelDefaults(TeamId teamId) {
    return watchWorkspaceChannel('language-model-defaults', _load, _channel);
  }

  @override
  Future<void> saveLanguageModelDefaults(
    TeamId teamId,
    LanguageModelDefaults defaults,
  ) async {
    await _client.put('/v1/language-model-defaults', {
      'blockModelId': defaults.blockModelId,
      'knowledgeAssistantModelId': defaults.knowledgeAssistantModelId,
    });
  }

  Future<LanguageModelDefaults> _load() async {
    final response = await _client.get('/v1/language-model-defaults');
    return LanguageModelDefaults(
      blockModelId: response['blockModelId'] as String?,
      knowledgeAssistantModelId:
          response['knowledgeAssistantModelId'] as String?,
    );
  }
}
