import 'dart:convert';
import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/repositories/file_version_repository.dart';
import '../../domain/repositories/team_file_repository.dart';

class LocalTeamFileRepository
    implements TeamFileRepository, FileVersionRepository {
  const LocalTeamFileRepository(this._client);

  final LocalRuntimeApiClient _client;

  @override
  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) async {
    if (name.trim().isEmpty) {
      return const Error(FileFailure(FileFailureKind.invalidFolderName));
    }
    try {
      return Success(
        _folderFrom(
          await _client.post('/v1/folders', {
            'name': name.trim(),
            'parentFolderId': parentFolderId,
          }),
        ),
      );
    } on Object {
      return const Error(FileFailure(FileFailureKind.createFolderFailed));
    }
  }

  @override
  Future<Result<TeamFile, FileFailure>> createVersion({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  }) => _write('/v1/files/${file.id}/versions', input, folderId: file.folderId);

  @override
  Future<Result<Uint8List, FileFailure>> downloadVersion(
    FileVersion version,
  ) async {
    try {
      final response = await _client.get(
        '/v1/files/${version.fileId}/versions/${version.id}/content',
      );
      final content = response['contentBase64'];
      if (content is! String) {
        return const Error(FileFailure(FileFailureKind.downloadFailed));
      }
      return Success(Uint8List.fromList(base64Decode(content)));
    } on Object {
      return const Error(FileFailure(FileFailureKind.downloadFailed));
    }
  }

  @override
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) => _write('/v1/files', input, folderId: folderId);

  @override
  Stream<List<TeamFile>> watchFiles(TeamId teamId) =>
      pollLocalRuntime(_loadFiles);

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) =>
      pollLocalRuntime(_loadFolders);

  @override
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId) =>
      pollLocalRuntime(() => _loadVersions(fileId));

  Future<Result<TeamFile, FileFailure>> _write(
    String path,
    UploadFileInput input, {
    required String? folderId,
  }) async {
    try {
      final response = await _client.post(path, {
        'name': input.name,
        'contentType': input.contentType,
        'contentBase64': base64Encode(input.bytes),
        'folderId': folderId,
      });
      return Success(_fileFrom(response));
    } on Object {
      return const Error(FileFailure(FileFailureKind.uploadFailed));
    }
  }

  Future<List<TeamFile>> _loadFiles() async {
    final response = await _client.get('/v1/files');
    return _items(response).map(_fileFrom).toList(growable: false);
  }

  Future<List<TeamFolder>> _loadFolders() async {
    final response = await _client.get('/v1/folders');
    return _items(response).map(_folderFrom).toList(growable: false);
  }

  Future<List<FileVersion>> _loadVersions(String fileId) async {
    final response = await _client.get('/v1/files/$fileId/versions');
    return _items(response).map(_versionFrom).toList(growable: false);
  }

  List<Map<dynamic, dynamic>> _items(Map<String, Object?> response) {
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Dateiliste ist ungültig.');
    }
    return items.whereType<Map>().toList(growable: false);
  }

  TeamFile _fileFrom(Map<dynamic, dynamic> value) {
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

  TeamFolder _folderFrom(Map<dynamic, dynamic> value) {
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

  FileVersion _versionFrom(Map<dynamic, dynamic> value) {
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
