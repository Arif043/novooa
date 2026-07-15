import '../repositories/team_repository.dart';

class UpdateCurrentTeamName {
  const UpdateCurrentTeamName(this._repository);

  final TeamRepository _repository;

  Future<void> call(String name) {
    return _repository.updateCurrentTeamName(name);
  }
}
