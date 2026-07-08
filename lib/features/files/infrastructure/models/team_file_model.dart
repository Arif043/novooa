import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_id.dart';

class TeamFileModel {
  const TeamFileModel({
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
  });

  final String id;
  final String teamId;
  final String ownerUid;
  final String displayName;
  final String storagePath;
  final String currentVersionId;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TeamFileModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return TeamFileModel(
      id: snapshot.id,
      teamId: data['teamId'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? snapshot.id,
      storagePath: data['storagePath'] as String? ?? '',
      currentVersionId: data['currentVersionId'] as String? ?? '',
      contentType: data['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  TeamFile toDomain() {
    return TeamFile(
      id: id,
      teamId: TeamId(teamId),
      ownerUid: ownerUid,
      displayName: displayName,
      storagePath: storagePath,
      currentVersionId: currentVersionId,
      contentType: contentType,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _timestampToDate(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}
