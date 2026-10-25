import '../../../files/domain/entities/team_id.dart';

abstract interface class TeamRepository {
  Future<TeamId> currentTeamId();
}
