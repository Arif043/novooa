import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/team_file.dart';
import '../entities/team_folder.dart';
import '../entities/team_id.dart';
import '../entities/upload_file_input.dart';

abstract interface class TeamFileRepository {
  Stream<List<TeamFile>> watchFiles(TeamId teamId);

  Stream<List<TeamFolder>> watchFolders(TeamId teamId);

  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  });

  /// Entfernt die Datei samt aller Versionen.
  Future<Result<Unit, FileFailure>> deleteFile({
    required TeamId teamId,
    required String fileId,
  });

  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  });
}
