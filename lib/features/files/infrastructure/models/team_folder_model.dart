import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';

class TeamFolderModel {
  const TeamFolderModel({
    required this.id,
    required this.teamId,
    required this.ownerUid,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.parentFolderId,
  });

  final String id;
  final String teamId;
  final String ownerUid;
  final String name;
  final String? parentFolderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TeamFolderModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return TeamFolderModel(
      id: snapshot.id,
      teamId: data['teamId'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? 'Verzeichnis',
      parentFolderId: data['parentFolderId'] as String?,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  TeamFolder toDomain() {
    return TeamFolder(
      id: id,
      teamId: TeamId(teamId),
      ownerUid: ownerUid,
      name: name,
      parentFolderId: parentFolderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _timestampToDate(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}
