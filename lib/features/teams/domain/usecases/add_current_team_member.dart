import '../repositories/team_repository.dart';

class AddCurrentTeamMember {
  const AddCurrentTeamMember(this._repository);

  final TeamRepository _repository;

  Future<void> call(String identifier) {
    return _repository.addCurrentTeamMember(identifier);
  }
}
