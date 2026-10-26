import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/plugin_activation.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/repositories/plugin_repository.dart';
import '../mappers/plugin_activation_mapper.dart';

class HttpPluginRepository implements PluginRepository {
  const HttpPluginRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<PluginActivation>> watchPlugins() =>
      watchWorkspaceChannel('plugins', _load, _channel);

  Future<List<PluginActivation>> _load() async {
    try {
      return PluginActivationMapper.listFrom(await _client.get('/v1/plugins'));
    } on Object catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<Result<PluginActivation, PluginFailure>> setEnabled(
    PluginId id, {
    required bool enabled,
  }) async {
    try {
      final response = await _client.put(
        '/v1/plugins/${Uri.encodeComponent(id.value)}',
        {'enabled': enabled},
      );
      final activation = PluginActivationMapper.activationFrom(response);
      if (activation == null) {
        return const Error(PluginFailure(PluginFailureKind.unexpected));
      }
      return Success(activation);
    } on Object catch (error) {
      return Error(_failureFor(error));
    }
  }

  PluginFailure _failureFor(Object error) => PluginFailure(switch (error) {
    WorkspaceConnectionException() => PluginFailureKind.runtimeUnavailable,
    WorkspaceHttpException(statusCode: 403) => PluginFailureKind.adminRequired,
    WorkspaceHttpException(statusCode: 404) => PluginFailureKind.notFound,
    _ => PluginFailureKind.unexpected,
  });
}
