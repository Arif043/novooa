import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';
import '../entities/file_version.dart';
import '../repositories/file_version_repository.dart';

class DownloadFileVersion {
  const DownloadFileVersion(this._repository);

  final FileVersionRepository _repository;

  Future<Result<Uint8List, FileFailure>> call(FileVersion version) {
    return _repository.downloadVersion(version);
  }
}
