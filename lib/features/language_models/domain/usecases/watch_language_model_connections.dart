import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model_connection.dart';
import '../repositories/language_model_connection_repository.dart';

class WatchLanguageModelConnections {
  const WatchLanguageModelConnections(this._repository);

  final LanguageModelConnectionRepository _repository;

  Stream<List<LanguageModelConnection>> call(TeamId teamId) {
    return _repository.watchConnections(teamId);
  }
}
