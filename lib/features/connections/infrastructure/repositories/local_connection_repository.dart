import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/connection.dart';
import '../../domain/entities/connection_draft.dart';
import '../../domain/entities/connection_failure.dart';
import '../../domain/entities/connection_test_result.dart';
import '../../domain/repositories/connection_repository.dart';
import 'connection_json_mapper.dart';

/// Verbindungen der lokalen Runtime über deren HTTP-API.
class LocalConnectionRepository implements ConnectionRepository {
  const LocalConnectionRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) {
    return watchWorkspaceChannel('connections', _load, _channel);
  }

  Future<List<Connection>> _load() async =>
      connectionsFromJson(await _client.get('/v1/connections'));

  @override
  Future<Result<Connection, ConnectionFailure>> create(ConnectionDraft draft) =>
      _attempt(
        ConnectionFailure.saveFailed,
        () async => connectionFromJson(
          await _client.post('/v1/connections', draftToJson(draft)),
        ),
      );

  @override
  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  ) => _attempt(
    ConnectionFailure.saveFailed,
    () async => connectionFromJson(
      await _client.put(
        '/v1/connections/${Uri.encodeComponent(id)}',
        draftToJson(draft),
      ),
    ),
  );

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) =>
      _attempt(ConnectionFailure.deleteFailed, () async {
        await _client.delete('/v1/connections/${Uri.encodeComponent(id)}');
        return unit;
      });

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  }) => _attempt(
    ConnectionFailure.testFailed,
    () async => testResultFromJson(
      await _client.post('/v1/connections/${Uri.encodeComponent(id)}/test', {
        if (path.trim().isNotEmpty) 'path': path.trim(),
      }),
    ),
  );

  Future<Result<T, ConnectionFailure>> _attempt<T extends Object>(
    ConnectionFailure fallback,
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(ConnectionFailure(error.message));
    } on Object {
      return Error(fallback);
    }
  }
}
