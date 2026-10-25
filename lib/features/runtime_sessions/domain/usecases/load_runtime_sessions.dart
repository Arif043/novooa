import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_session.dart';
import '../entities/runtime_session_failure.dart';
import '../repositories/runtime_session_repository.dart';

class LoadRuntimeSessions {
  const LoadRuntimeSessions(this._repository);

  final RuntimeSessionRepository _repository;

  Future<Result<List<RuntimeSession>, RuntimeSessionFailure>> call() {
    return _repository.listSessions();
  }
}
