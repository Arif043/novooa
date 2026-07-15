import '../../../files/domain/entities/team_id.dart';
import '../repositories/team_repository.dart';

class GetCurrentTeamId {
  const GetCurrentTeamId(this._repository);

  final TeamRepository _repository;

  Future<TeamId> call() {
    return _repository.currentTeamId();
  }
}
