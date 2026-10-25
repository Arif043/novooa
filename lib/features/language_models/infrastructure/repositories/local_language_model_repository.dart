import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_connection.dart';
import '../../domain/entities/language_model_connection_draft.dart';
import '../../domain/entities/language_model_provider.dart';
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
      if (draft.provider.hasEndpoint) 'baseUrl': draft.baseUrl,
      'apiKey': draft.apiKey,
    });
  }

  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) {
    return watchWorkspaceChannel('language-models', _load, _channel);
  }

  @override
  Stream<List<LanguageModelConnection>> watchConnections(TeamId teamId) {
    return watchWorkspaceChannel('language-models', _loadConnections, _channel);
  }

  @override
  Future<void> removeConnection(TeamId teamId, String connectionId) async {
    await _client.delete('/v1/language-model-connections/$connectionId');
  }

  Future<List<LanguageModel>> _load() async {
    final response = await _client.get('/v1/language-models');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException(
        'Sprachmodelle konnten nicht gelesen werden.',
      );
    }
    final providers = await _providersByConnection();
    return items
        .map((item) => _modelFrom(item, providers))
        .toList(growable: false);
  }

  /// Der Anbieter hängt an der Verbindung, nicht am Modell selbst.
  Future<Map<String, LanguageModelProvider>> _providersByConnection() async {
    final connections = await _loadConnections();
    return {
      for (final connection in connections) connection.id: connection.provider,
    };
  }

  Future<List<LanguageModelConnection>> _loadConnections() async {
    final response = await _client.get('/v1/language-model-connections');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException(
        'Anbieter-Verbindungen konnten nicht gelesen werden.',
      );
    }
    return items.map(_connectionFrom).toList(growable: false);
  }

  LanguageModel _modelFrom(
    Object? value,
    Map<String, LanguageModelProvider> providers,
  ) {
    final model = _asRecord(value, 'Sprachmodell');
    final capabilities = model['capabilities'];
    if (capabilities is! Map) {
      throw const FormatException('Sprachmodell ist ungültig.');
    }
    return LanguageModel(
      id: _text(model, 'id'),
      name: _text(model, 'name'),
      modelId: _text(model, 'modelId'),
      connectionId: model['connectionId'] as String?,
      provider: providers[model['connectionId']],
      supportsImageInput: capabilities['imageInput'] == true,
      supportsStructuredOutput: capabilities['structuredOutput'] == true,
      supportsImageGeneration: capabilities['imageGeneration'] == true,
    );
  }

  LanguageModelConnection _connectionFrom(Object? value) {
    final connection = _asRecord(value, 'Anbieter-Verbindung');
    return LanguageModelConnection(
      id: _text(connection, 'id'),
      name: _text(connection, 'name'),
      provider: LanguageModelProvider.fromId(_text(connection, 'provider')),
      baseUrl: connection['baseUrl'] as String?,
    );
  }

  Map<String, Object?> _asRecord(Object? value, String label) {
    if (value is! Map) throw FormatException('$label ist ungültig.');
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }

  String _text(Map<String, Object?> model, String field) {
    final value = model[field];
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException('Sprachmodell ist ungültig.');
  }
}
