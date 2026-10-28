import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

/// Der aktuelle Stand einer Datei; `null`, wenn es sie nicht mehr gibt.
class FindTeamFile {
  const FindTeamFile(this._repository);

  final TeamFileRepository _repository;

  Future<TeamFile?> call(TeamId teamId, String fileId) async {
    final files = await _repository.watchFiles(teamId).first;
    return files.where((file) => file.id == fileId).firstOrNull;
  }
}
