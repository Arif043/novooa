import '../entities/team_folder.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

class WatchTeamFolders {
  const WatchTeamFolders(this._repository);

  final TeamFileRepository _repository;

  Stream<List<TeamFolder>> call(TeamId teamId) {
    return _repository.watchFolders(teamId);
  }
}
