import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

class WatchTeamFiles {
  const WatchTeamFiles(this._repository);

  final TeamFileRepository _repository;

  Stream<List<TeamFile>> call(TeamId teamId) {
    return _repository.watchFiles(teamId);
  }
}
