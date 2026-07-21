import '../entities/file_version.dart';
import '../entities/team_id.dart';
import '../repositories/file_version_repository.dart';

class WatchFileVersions {
  const WatchFileVersions(this._repository);

  final FileVersionRepository _repository;

  Stream<List<FileVersion>> call(TeamId teamId, String fileId) {
    return _repository.watchVersions(teamId, fileId);
  }
}
