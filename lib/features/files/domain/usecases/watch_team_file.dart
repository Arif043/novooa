import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

/// Eine einzelne Datei; `null`, sobald sie nicht mehr existiert.
class WatchTeamFile {
  const WatchTeamFile(this._repository);

  final TeamFileRepository _repository;

  Stream<TeamFile?> call(TeamId teamId, String fileId) {
    return _repository
        .watchFiles(teamId)
        .map((files) => files.where((file) => file.id == fileId).firstOrNull)
        .distinct(_sameState);
  }

  bool _sameState(TeamFile? previous, TeamFile? next) {
    return previous?.displayName == next?.displayName &&
        previous?.folderId == next?.folderId &&
        previous?.currentVersionId == next?.currentVersionId &&
        (previous == null) == (next == null);
  }
}
