import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/repositories/file_settings_repository.dart';

class LocalFileSettingsRepository implements FileSettingsRepository {
  const LocalFileSettingsRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<int> watchVersionLimit() =>
      watchWorkspaceChannel('file-settings', _load, _channel);

  @override
  Future<void> saveVersionLimit(int limit) async {
    await _client.put('/v1/file-settings', {'versionLimit': limit});
  }

  Future<int> _load() async {
    final response = await _client.get('/v1/file-settings');
    final limit = response['versionLimit'];
    if (limit is! int) {
      throw const FormatException('Das Versionslimit ist ungültig.');
    }
    return limit;
  }
}
