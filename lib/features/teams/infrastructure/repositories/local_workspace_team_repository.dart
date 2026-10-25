import '../../../files/domain/entities/team_id.dart';
import '../../domain/repositories/team_repository.dart';

class LocalWorkspaceTeamRepository implements TeamRepository {
  const LocalWorkspaceTeamRepository({required this.teamId});

  final String teamId;

  @override
  Future<TeamId> currentTeamId() async => TeamId(teamId);
}
