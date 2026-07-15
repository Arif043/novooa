import '../entities/team_member.dart';
import '../entities/team_workspace.dart';

abstract interface class TeamRepository {
  Stream<TeamWorkspace> watchCurrentTeam();

  Stream<List<TeamMember>> watchCurrentTeamMembers();

  Future<void> updateCurrentTeamName(String name);
}
