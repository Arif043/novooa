import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/connection.dart';
import '../entities/connection_draft.dart';
import '../entities/connection_failure.dart';
import '../entities/connection_test_result.dart';
import '../repositories/connection_repository.dart';

class WatchConnections {
  const WatchConnections(this._repository);

  final ConnectionRepository _repository;

  Stream<List<Connection>> call(TeamId teamId) =>
      _repository.watchConnections(teamId);
}

class CreateConnection {
  const CreateConnection(this._repository);

  final ConnectionRepository _repository;

  Future<Result<Connection, ConnectionFailure>> call(ConnectionDraft draft) =>
      _repository.create(draft);
}

class UpdateConnection {
  const UpdateConnection(this._repository);

  final ConnectionRepository _repository;

  Future<Result<Connection, ConnectionFailure>> call(
    String id,
    ConnectionDraft draft,
  ) => _repository.update(id, draft);
}

class DeleteConnection {
  const DeleteConnection(this._repository);

  final ConnectionRepository _repository;

  Future<Result<Unit, ConnectionFailure>> call(String id) =>
      _repository.delete(id);
}

class TestConnection {
  const TestConnection(this._repository);

  final ConnectionRepository _repository;

  Future<Result<ConnectionTestResult, ConnectionFailure>> call(
    String id, {
    String path = '',
  }) => _repository.test(id, path: path);
}
