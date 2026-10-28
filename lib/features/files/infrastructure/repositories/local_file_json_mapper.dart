import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';

/// Übersetzt die Datei-DTOs der Runtime in Domain-Entitäten; fehlende Felder
/// bekommen neutrale Werte, damit eine Liste nicht an einem Eintrag scheitert.
class LocalFileJsonMapper {
  const LocalFileJsonMapper();

  TeamFile fileFrom(Map<dynamic, dynamic> value) {
    final data = _data(value);
    return TeamFile(
      id: _string(data['id']),
      teamId: TeamId(_string(data['teamId'])),
      ownerUid: _string(data['ownerUid']),
      displayName: _string(data['displayName']),
      storagePath: _string(data['storagePath']),
      currentVersionId: _string(data['currentVersionId']),
      contentType: _string(
        data['contentType'],
        fallback: 'application/octet-stream',
      ),
      sizeBytes: _integer(data['sizeBytes']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      currentVersionCreatedAt: _date(data['currentVersionCreatedAt']),
      folderId: _nullableString(data['folderId']),
    );
  }

  TeamFolder folderFrom(Map<dynamic, dynamic> value) {
    final data = _data(value);
    return TeamFolder(
      id: _string(data['id']),
      teamId: TeamId(_string(data['teamId'])),
      ownerUid: _string(data['ownerUid']),
      name: _string(data['name']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      parentFolderId: _nullableString(data['parentFolderId']),
    );
  }

  FileVersion versionFrom(Map<dynamic, dynamic> value) {
    final data = _data(value);
    return FileVersion(
      id: _string(data['id']),
      fileId: _string(data['fileId']),
      teamId: TeamId(_string(data['teamId'])),
      createdByUid: _string(data['createdByUid']),
      displayName: _string(data['displayName']),
      storagePath: _string(data['storagePath']),
      contentType: _string(
        data['contentType'],
        fallback: 'application/octet-stream',
      ),
      sizeBytes: _integer(data['sizeBytes']),
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, Object?> _data(Map<dynamic, dynamic> value) => {
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };

  DateTime _date(Object? value) => value is String
      ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.fromMillisecondsSinceEpoch(0);

  int _integer(Object? value) => value is int ? value : 0;

  String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
