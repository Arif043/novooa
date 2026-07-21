import 'team_id.dart';

class FileVersion {
  const FileVersion({
    required this.id,
    required this.fileId,
    required this.teamId,
    required this.createdByUid,
    required this.displayName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String fileId;
  final TeamId teamId;
  final String createdByUid;
  final String displayName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
}
