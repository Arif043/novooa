import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_session_failure.dart';
import '../repositories/runtime_session_repository.dart';

class RevokeOtherRuntimeSessions {
  const RevokeOtherRuntimeSessions(this._repository);

  final RuntimeSessionRepository _repository;

  /// Liefert die Zahl der beendeten Sitzungen.
  Future<Result<int, RuntimeSessionFailure>> call() {
    return _repository.revokeOtherSessions();
  }
}
