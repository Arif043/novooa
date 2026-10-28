import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_version.dart';
import '../entities/team_file.dart';
import '../repositories/file_version_repository.dart';

class RestoreFileVersion {
  const RestoreFileVersion(this._repository);

  final FileVersionRepository _repository;

  Future<Result<TeamFile, FileFailure>> call(FileVersion version) {
    return _repository.restoreVersion(version);
  }
}
