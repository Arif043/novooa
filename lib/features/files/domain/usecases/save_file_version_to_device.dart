import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_version.dart';
import '../entities/team_file.dart';
import '../repositories/file_save_gateway.dart';
import '../repositories/file_version_repository.dart';

/// Lädt eine Version und legt sie unter dem heutigen Dateinamen auf dem Gerät ab.
class SaveFileVersionToDevice {
  const SaveFileVersionToDevice(this._versions, this._gateway);

  final FileVersionRepository _versions;
  final FileSaveGateway _gateway;

  Future<Result<Unit, FileFailure>> call(
    TeamFile file,
    FileVersion version,
  ) async {
    final bytesOrFailure = await _versions.downloadVersion(version);
    return bytesOrFailure.when(
      (bytes) => _gateway.save(fileName: file.displayName, bytes: bytes),
      (failure) async => Error(failure),
    );
  }
}
