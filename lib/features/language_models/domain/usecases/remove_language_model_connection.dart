import '../../../files/domain/entities/team_id.dart';
import '../repositories/language_model_connection_repository.dart';

class RemoveLanguageModelConnection {
  const RemoveLanguageModelConnection(this._repository);

  final LanguageModelConnectionRepository _repository;

  Future<void> call(TeamId teamId, String connectionId) {
    return _repository.removeConnection(teamId, connectionId);
  }
}
