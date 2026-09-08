import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_workspace.dart';
import '../../domain/repositories/team_repository.dart';

class LocalWorkspaceTeamRepository implements TeamRepository {
  const LocalWorkspaceTeamRepository({
    required this.teamId,
    required this.userId,
  });

  final String teamId;
  final String userId;

  @override
  Future<void> addCurrentTeamMember(String identifier) {
    throw UnsupportedError(
      'Lokale Arbeitsbereiche haben keine Mitgliederverwaltung.',
    );
  }

  @override
  Future<TeamId> currentTeamId() async => TeamId(teamId);

  @override
  Future<void> removeCurrentTeamMember(String uid) {
    throw UnsupportedError(
      'Lokale Arbeitsbereiche haben keine Mitgliederverwaltung.',
    );
  }

  @override
  Future<void> updateCurrentTeamName(String name) {
    throw UnsupportedError(
      'Der lokale Arbeitsbereich wird durch die Runtime verwaltet.',
    );
  }

  @override
  Stream<TeamWorkspace> watchCurrentTeam() => Stream.value(
    TeamWorkspace(id: teamId, name: 'Lokaler Arbeitsbereich', ownerUid: userId),
  );

  @override
  Stream<TeamId> watchCurrentTeamId() => Stream.value(TeamId(teamId));

  @override
  Stream<List<TeamMember>> watchCurrentTeamMembers() => Stream.value([
    TeamMember(
      uid: userId,
      role: TeamMemberRole.owner,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ]);
}
