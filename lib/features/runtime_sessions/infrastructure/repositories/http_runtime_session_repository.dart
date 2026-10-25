import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/revoked_sessions.dart';
import '../../domain/entities/runtime_session_failure.dart';
import '../../domain/repositories/runtime_session_repository.dart';

class HttpRuntimeSessionRepository implements RuntimeSessionRepository {
  const HttpRuntimeSessionRepository(this._runtimeClient);

  final WorkspaceApiClient _runtimeClient;

  @override
  Future<Result<RevokedSessions, RuntimeSessionFailure>>
  revokeOtherSessions() async {
    try {
      final response = await _runtimeClient.post(
        '/v1/auth/sessions/revoke-others',
        const {},
      );
      final revoked = response['revoked'];
      if (revoked is! int || revoked < 0) return _failure(_unexpected);
      return Success(RevokedSessions(revoked));
    } on WorkspaceConnectionException {
      return _failure(RuntimeSessionFailureKind.runtimeUnavailable);
    } on Object {
      return _failure(_unexpected);
    }
  }

  static const _unexpected = RuntimeSessionFailureKind.unexpected;

  Result<RevokedSessions, RuntimeSessionFailure> _failure(
    RuntimeSessionFailureKind kind,
  ) => Error(RuntimeSessionFailure(kind));
}
