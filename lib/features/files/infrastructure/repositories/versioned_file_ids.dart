import 'package:syscat2/core/entities/unique_id.dart';

class VersionedFileIds {
  VersionedFileIds()
    : fileId = UniqueId.random().value,
      versionId = UniqueId.random().value;

  VersionedFileIds.existing(this.fileId) : versionId = UniqueId.random().value;

  final String fileId;
  final String versionId;
}
