import 'package:multiple_result/multiple_result.dart';

import '../entities/revoked_sessions.dart';
import '../entities/runtime_session_failure.dart';

abstract interface class RuntimeSessionRepository {
  /// Beendet alle Sitzungen der Runtime außer der eigenen.
  Future<Result<RevokedSessions, RuntimeSessionFailure>> revokeOtherSessions();
}
