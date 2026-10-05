import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/connection.dart';
import '../../domain/entities/connection_draft.dart';
import '../../domain/entities/connection_failure.dart';
import '../../domain/entities/connection_test_result.dart';
import '../../domain/repositories/connection_repository.dart';

/// Für Betriebsvarianten ohne Verbindungs-Speicher (Cloud).
class UnavailableConnectionRepository implements ConnectionRepository {
  const UnavailableConnectionRepository();

  static const _failure = ConnectionFailure(
    'Verbindungen sind in dieser Betriebsvariante noch nicht verfügbar.',
  );

  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) =>
      Stream.value(const []);

  @override
  Future<Result<Connection, ConnectionFailure>> create(
    ConnectionDraft draft,
  ) async => const Error(_failure);

  @override
  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  ) async => const Error(_failure);

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) async =>
      const Error(_failure);

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  }) async => const Error(_failure);
}
