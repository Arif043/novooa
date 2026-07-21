import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_id.dart';

class FileVersionModel {
  const FileVersionModel({
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

  factory FileVersionModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    TeamId teamId,
  ) {
    final data = snapshot.data() ?? {};
    return FileVersionModel(
      id: snapshot.id,
      fileId: data['fileId'] as String? ?? '',
      teamId: teamId,
      createdByUid: data['createdByUid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? snapshot.id,
      storagePath: data['storagePath'] as String? ?? '',
      contentType: data['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
      createdAt: _timestampToDate(data['createdAt']),
    );
  }

  FileVersion toDomain() => FileVersion(
    id: id,
    fileId: fileId,
    teamId: teamId,
    createdByUid: createdByUid,
    displayName: displayName,
    storagePath: storagePath,
    contentType: contentType,
    sizeBytes: sizeBytes,
    createdAt: createdAt,
  );

  static DateTime _timestampToDate(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}
