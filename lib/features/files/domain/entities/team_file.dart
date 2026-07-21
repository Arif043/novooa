import 'team_id.dart';

class TeamFile {
  const TeamFile({
    required this.id,
    required this.teamId,
    required this.ownerUid,
    required this.displayName,
    required this.storagePath,
    required this.currentVersionId,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.currentVersionCreatedAt,
    this.folderId,
  });

  final String id;
  final TeamId teamId;
  final String ownerUid;
  final String displayName;
  final String storagePath;
  final String currentVersionId;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime currentVersionCreatedAt;
  final String? folderId;
}
