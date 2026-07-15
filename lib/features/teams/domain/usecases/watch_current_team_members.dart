import '../entities/team_member.dart';
import '../repositories/team_repository.dart';

class WatchCurrentTeamMembers {
  const WatchCurrentTeamMembers(this._repository);

  final TeamRepository _repository;

  Stream<List<TeamMember>> call() {
    return _repository.watchCurrentTeamMembers();
  }
}
