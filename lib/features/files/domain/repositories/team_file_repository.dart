import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../entities/upload_file_input.dart';

abstract interface class TeamFileRepository {
  Stream<List<TeamFile>> watchFiles(TeamId teamId);

  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
  });
}
