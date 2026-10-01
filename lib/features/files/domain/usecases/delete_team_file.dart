import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

class DeleteTeamFile {
  const DeleteTeamFile(this._repository);

  final TeamFileRepository _repository;

  Future<Result<Unit, FileFailure>> call({
    required TeamId teamId,
    required String fileId,
  }) {
    return _repository.deleteFile(teamId: teamId, fileId: fileId);
  }
}
