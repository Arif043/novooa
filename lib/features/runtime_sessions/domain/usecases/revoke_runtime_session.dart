import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_session.dart';
import '../entities/runtime_session_failure.dart';
import '../repositories/runtime_session_repository.dart';

class RevokeRuntimeSession {
  const RevokeRuntimeSession(this._repository);

  final RuntimeSessionRepository _repository;

  Future<Result<Unit, RuntimeSessionFailure>> call(RuntimeSession session) {
    return _repository.revokeSession(session.id);
  }
}
