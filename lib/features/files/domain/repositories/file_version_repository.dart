import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_version.dart';
import '../entities/team_file.dart';
import '../entities/team_id.dart';
import '../entities/upload_file_input.dart';

abstract interface class FileVersionRepository {
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId);

  Future<Result<Uint8List, FileFailure>> downloadVersion(FileVersion version);

  Future<Result<TeamFile, FileFailure>> createVersion({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  });

  /// Der Inhalt von [version] wird eine neue aktuelle Version; nichts wird
  /// überschrieben.
  Future<Result<TeamFile, FileFailure>> restoreVersion(FileVersion version);
}
