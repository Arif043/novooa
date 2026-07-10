import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_folder.dart';
import '../entities/team_id.dart';
import '../repositories/team_file_repository.dart';

class CreateTeamFolder {
  const CreateTeamFolder(this._repository);

  final TeamFileRepository _repository;

  Future<Result<TeamFolder, FileFailure>> call({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) {
    return _repository.createFolder(
      teamId: teamId,
      ownerUid: ownerUid,
      name: name,
      parentFolderId: parentFolderId,
    );
  }
}
