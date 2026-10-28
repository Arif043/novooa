import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_name.dart';
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

  /// Nur der Name ändert sich; Versionen bleiben. `nameTaken`, wenn der Name
  /// im Verzeichnis schon vergeben ist.
  Future<Result<TeamFile, FileFailure>> renameFile({
    required TeamFile file,
    required FileName name,
  });

  /// `folderId == null` ist die oberste Ebene.
  Future<Result<TeamFile, FileFailure>> moveFile({
    required TeamFile file,
    required String? folderId,
  });

  /// Neue Datei mit dem Inhalt der aktuellen Version im selben Verzeichnis;
  /// ist [name] vergeben, hängt die Runtime eine Nummer an.
  Future<Result<TeamFile, FileFailure>> copyFile({
    required TeamFile file,
    required FileName name,
  });

  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  });
}
