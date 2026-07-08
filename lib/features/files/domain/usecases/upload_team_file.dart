import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../entities/upload_file_input.dart';
import '../repositories/team_file_repository.dart';

class UploadTeamFile {
  const UploadTeamFile(this._repository);

  final TeamFileRepository _repository;

  Future<Result<TeamFile, FileFailure>> call({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
  }) {
    return _repository.uploadFile(
      teamId: teamId,
      ownerUid: ownerUid,
      input: input,
    );
  }
}
