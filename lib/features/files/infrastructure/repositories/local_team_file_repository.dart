import 'dart:convert';
import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_name.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/repositories/file_version_repository.dart';
import '../../domain/repositories/team_file_repository.dart';
import 'local_file_json_mapper.dart';
import 'local_file_mutation_requests.dart';

class LocalTeamFileRepository
    implements TeamFileRepository, FileVersionRepository {
  LocalTeamFileRepository(this._client, this._channel)
    : _mutations = LocalFileMutationRequests(_client);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;
  final LocalFileMutationRequests _mutations;
  static const _mapper = LocalFileJsonMapper();

  @override
  Future<Result<TeamFile, FileFailure>> renameFile({
    required TeamFile file,
    required FileName name,
  }) => _mutations.rename(file, name);

  @override
  Future<Result<TeamFile, FileFailure>> moveFile({
    required TeamFile file,
    required String? folderId,
  }) => _mutations.move(file, folderId);

  @override
  Future<Result<TeamFile, FileFailure>> copyFile({
    required TeamFile file,
    required FileName name,
  }) => _mutations.copy(file, name);

  @override
  Future<Result<TeamFile, FileFailure>> restoreVersion(FileVersion version) =>
      _mutations.restore(version);

  @override
  Future<Result<Unit, FileFailure>> deleteFile({
    required TeamId teamId,
    required String fileId,
  }) async {
    try {
      await _client.delete('/v1/files/$fileId');
      return const Success(unit);
    } on Object {
      return const Error(FileFailure(FileFailureKind.deleteFailed));
    }
  }

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
        _mapper.folderFrom(
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
      watchWorkspaceChannel('files', _loadFiles, _channel);

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) =>
      watchWorkspaceChannel('folders', _loadFolders, _channel);

  @override
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId) =>
      watchWorkspaceChannel(
        'file-versions:$fileId',
        () => _loadVersions(fileId),
        _channel,
      );

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
      return Success(_mapper.fileFrom(response));
    } on Object {
      return const Error(FileFailure(FileFailureKind.uploadFailed));
    }
  }

  Future<List<TeamFile>> _loadFiles() async {
    final response = await _client.get('/v1/files');
    return _items(response).map(_mapper.fileFrom).toList(growable: false);
  }

  Future<List<TeamFolder>> _loadFolders() async {
    final response = await _client.get('/v1/folders');
    return _items(response).map(_mapper.folderFrom).toList(growable: false);
  }

  Future<List<FileVersion>> _loadVersions(String fileId) async {
    final response = await _client.get('/v1/files/$fileId/versions');
    return _items(response).map(_mapper.versionFrom).toList(growable: false);
  }

  List<Map<dynamic, dynamic>> _items(Map<String, Object?> response) {
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Dateiliste ist ungültig.');
    }
    return items.whereType<Map>().toList(growable: false);
  }
}
