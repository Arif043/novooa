import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_name.dart';
import '../entities/team_file.dart';
import '../repositories/team_file_repository.dart';

class CopyTeamFile {
  const CopyTeamFile(this._repository);

  final TeamFileRepository _repository;

  /// [copyName] ist der Wunschname, z. B. `Bericht (Kopie).pdf`.
  Future<Result<TeamFile, FileFailure>> call(TeamFile file, FileName copyName) {
    return _repository.copyFile(file: file, name: copyName);
  }
}
