import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_file.dart';
import '../entities/upload_file_input.dart';
import '../repositories/file_version_repository.dart';

class CreateFileVersion {
  const CreateFileVersion(this._repository);

  final FileVersionRepository _repository;

  Future<Result<TeamFile, FileFailure>> call({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  }) {
    return _repository.createVersion(
      file: file,
      ownerUid: ownerUid,
      input: input,
    );
  }
}
