import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/entities/plugin_settings.dart';
import '../../domain/repositories/plugin_repository.dart';
import 'plugin_json_mapper.dart';

/// Plugin-Ordner der lokalen Runtime über deren HTTP-API.
class LocalPluginRepository implements PluginRepository {
  const LocalPluginRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId) {
    return watchWorkspaceChannel('plugins', _load, _channel);
  }

  Future<List<InstalledPlugin>> _load() async =>
      pluginsFromJson(await _client.get('/v1/plugins'));

  @override
  Future<Result<Unit, PluginFailure>> uninstall(String pluginId) => _attempt(
    PluginFailure.uninstallFailed,
    () async {
      await _client.delete('/v1/plugins/${Uri.encodeComponent(pluginId)}');
      return unit;
    },
  );

  @override
  Future<Result<PluginSettings, PluginFailure>> settings(String pluginId) =>
      _attempt(
        PluginFailure.loadFailed,
        () async => settingsFromJson(
          await _client.get(
            '/v1/plugins/${Uri.encodeComponent(pluginId)}/settings',
          ),
        ),
      );

  @override
  Future<Result<Unit, PluginFailure>> saveSettings(
    String pluginId,
    Map<String, Object> values,
  ) => _attempt(PluginFailure.settingsFailed, () async {
    await _client.put('/v1/plugins/${Uri.encodeComponent(pluginId)}/settings', {
      'values': values,
    });
    return unit;
  });

  Future<Result<T, PluginFailure>> _attempt<T extends Object>(
    PluginFailure fallback,
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(PluginFailure(error.message));
    } on Object {
      return Error(fallback);
    }
  }
}
