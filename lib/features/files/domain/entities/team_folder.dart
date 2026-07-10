import 'team_id.dart';

class TeamFolder {
  const TeamFolder({
    required this.id,
    required this.teamId,
    required this.ownerUid,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.parentFolderId,
  });

  final String id;
  final TeamId teamId;
  final String ownerUid;
  final String name;
  final String? parentFolderId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
