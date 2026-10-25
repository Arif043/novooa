import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_session.dart';
import '../entities/runtime_session_failure.dart';

abstract interface class RuntimeSessionRepository {
  /// Die gültigen Sitzungen des eigenen Kontos, zuletzt aktive zuerst.
  Future<Result<List<RuntimeSession>, RuntimeSessionFailure>> listSessions();

  /// Beendet eine andere Sitzung des eigenen Kontos.
  Future<Result<Unit, RuntimeSessionFailure>> revokeSession(
    RuntimeSessionId id,
  );

  /// Beendet alle Sitzungen des eigenen Kontos außer der eigenen und liefert,
  /// wie viele es waren.
  Future<Result<int, RuntimeSessionFailure>> revokeOtherSessions();
}
