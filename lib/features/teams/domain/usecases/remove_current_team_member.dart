import '../repositories/team_repository.dart';

class RemoveCurrentTeamMember {
  const RemoveCurrentTeamMember(this._repository);

  final TeamRepository _repository;

  Future<void> call(String uid) {
    return _repository.removeCurrentTeamMember(uid);
  }
}
