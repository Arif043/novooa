import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/connection.dart';
import '../entities/connection_draft.dart';
import '../entities/connection_failure.dart';
import '../entities/connection_test_result.dart';

/// Gespeicherte Zugänge zu externen Systemen. `watchConnections` liest neu,
/// wenn sich dort etwas ändert.
abstract class ConnectionRepository {
  Stream<List<Connection>> watchConnections(TeamId teamId);

  Future<Result<Connection, ConnectionFailure>> create(ConnectionDraft draft);

  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  );

  Future<Result<Unit, ConnectionFailure>> delete(String id);

  /// [path] ist ein optionaler Pfad unter der Basis-URL, der für den Test
  /// abgefragt wird.
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  });
}
