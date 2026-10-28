import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_file.dart';
import '../repositories/team_file_repository.dart';

class MoveTeamFile {
  const MoveTeamFile(this._repository);

  final TeamFileRepository _repository;

  Future<Result<TeamFile, FileFailure>> call(TeamFile file, String? folderId) {
    if (folderId == file.folderId) return Future.value(Success(file));
    return _repository.moveFile(file: file, folderId: folderId);
  }
}
