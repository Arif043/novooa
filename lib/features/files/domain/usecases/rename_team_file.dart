import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_name.dart';
import '../entities/team_file.dart';
import '../repositories/team_file_repository.dart';

class RenameTeamFile {
  const RenameTeamFile(this._repository);

  final TeamFileRepository _repository;

  Future<Result<TeamFile, FileFailure>> call(TeamFile file, FileName name) {
    if (name.value == file.displayName) return Future.value(Success(file));
    return _repository.renameFile(file: file, name: name);
  }
}
