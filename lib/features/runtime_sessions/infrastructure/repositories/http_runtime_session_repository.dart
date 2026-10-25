import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/runtime_session.dart';
import '../../domain/entities/runtime_session_failure.dart';
import '../../domain/repositories/runtime_session_repository.dart';
import '../mappers/runtime_session_mapper.dart';

class HttpRuntimeSessionRepository implements RuntimeSessionRepository {
  const HttpRuntimeSessionRepository(this._runtimeClient);

  final WorkspaceApiClient _runtimeClient;

  @override
  Future<Result<List<RuntimeSession>, RuntimeSessionFailure>> listSessions() =>
      _guarded(() async {
        final response = await _runtimeClient.get('/v1/auth/sessions');
        return Success(RuntimeSessionMapper.sessionsFrom(response));
      });

  @override
  Future<Result<Unit, RuntimeSessionFailure>> revokeSession(
    RuntimeSessionId id,
  ) => _guarded(() async {
    await _runtimeClient.delete(
      '/v1/auth/sessions/${Uri.encodeComponent(id.value)}',
    );
    return const Success(unit);
  });

  @override
  Future<Result<int, RuntimeSessionFailure>> revokeOtherSessions() =>
      _guarded(() async {
        final response = await _runtimeClient.post(
          '/v1/auth/sessions/revoke-others',
          const {},
        );
        final revoked = response['revoked'];
        if (revoked is! int || revoked < 0) return _failure(_unexpected);
        return Success(revoked);
      });

  static const _unexpected = RuntimeSessionFailureKind.unexpected;

  Future<Result<T, RuntimeSessionFailure>> _guarded<T extends Object>(
    Future<Result<T, RuntimeSessionFailure>> Function() request,
  ) async {
    try {
      return await request();
    } on WorkspaceConnectionException {
      return _failure(RuntimeSessionFailureKind.runtimeUnavailable);
    } on WorkspaceHttpException catch (error) {
      if (error.statusCode == 404) {
        return _failure(RuntimeSessionFailureKind.notFound);
      }
      return _failure(_unexpected);
    } on Object {
      return _failure(_unexpected);
    }
  }

  Result<T, RuntimeSessionFailure> _failure<T extends Object>(
    RuntimeSessionFailureKind kind,
  ) => Error(RuntimeSessionFailure(kind));
}
