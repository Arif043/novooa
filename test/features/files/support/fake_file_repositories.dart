import 'dart:async';
import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/file_name.dart';
import 'package:syscat2/features/files/domain/entities/file_version.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/domain/repositories/file_save_gateway.dart';
import 'package:syscat2/features/files/domain/repositories/file_version_repository.dart';
import 'package:syscat2/features/files/domain/repositories/team_file_repository.dart';

TeamFile testFile({
  String id = 'file.1',
  String name = 'Bericht.txt',
  String versionId = 'version.2',
  String contentType = 'text/plain',
  String? folderId,
}) => TeamFile(
  id: id,
  teamId: TeamId('team.1'),
  ownerUid: 'user.1',
  displayName: name,
  storagePath: 'path',
  currentVersionId: versionId,
  contentType: contentType,
  sizeBytes: 2048,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 28),
  currentVersionCreatedAt: DateTime(2026, 10, 28, 13, 48),
  folderId: folderId,
);

FileVersion testVersion(String id, {int sizeBytes = 2048, int day = 28}) =>
    FileVersion(
      id: id,
      fileId: 'file.1',
      teamId: TeamId('team.1'),
      createdByUid: 'system',
      displayName: 'Bericht.txt',
      storagePath: 'path/$id',
      contentType: 'text/plain',
      sizeBytes: sizeBytes,
      createdAt: DateTime(2026, 10, day, 12),
    );

/// Beide Datei-Ports in einem Double; Streams lassen sich im Test füttern,
/// Aufrufe werden mitgeschrieben, Ergebnisse sind vorgebbar.
class FakeFileRepositories
    implements TeamFileRepository, FileVersionRepository {
  final files = StreamController<List<TeamFile>>.broadcast();
  final versions = StreamController<List<FileVersion>>.broadcast();
  final calls = <String>[];
  final downloaded = <String>[];
  FileFailureKind? failWith;
  UploadFileInput? createdInput;
  FileName? lastName;
  String? lastFolderId;

  Future<Result<TeamFile, FileFailure>> _answer(String call, TeamFile file) {
    calls.add(call);
    final failure = failWith;
    return Future.value(
      failure == null ? Success(file) : Error(FileFailure(failure)),
    );
  }

  @override
  Future<Result<TeamFile, FileFailure>> renameFile({
    required TeamFile file,
    required FileName name,
  }) {
    lastName = name;
    return _answer('rename', testFile(name: name.value));
  }

  @override
  Future<Result<TeamFile, FileFailure>> moveFile({
    required TeamFile file,
    required String? folderId,
  }) {
    lastFolderId = folderId;
    return _answer('move', testFile(folderId: folderId));
  }

  @override
  Future<Result<TeamFile, FileFailure>> copyFile({
    required TeamFile file,
    required FileName name,
  }) {
    lastName = name;
    return _answer('copy', testFile(id: 'file.copy', name: name.value));
  }

  @override
  Future<Result<TeamFile, FileFailure>> restoreVersion(FileVersion version) =>
      _answer('restore:${version.id}', testFile());

  @override
  Future<Result<TeamFile, FileFailure>> createVersion({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  }) {
    createdInput = input;
    return _answer('createVersion', file);
  }

  @override
  Future<Result<Unit, FileFailure>> deleteFile({
    required TeamId teamId,
    required String fileId,
  }) async {
    calls.add('delete:$fileId');
    return Success.unit();
  }

  @override
  Future<Result<Uint8List, FileFailure>> downloadVersion(
    FileVersion version,
  ) async {
    downloaded.add(version.id);
    return Success(Uint8List.fromList(version.id.codeUnits));
  }

  @override
  Stream<List<TeamFile>> watchFiles(TeamId teamId) => files.stream;

  @override
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId) =>
      versions.stream;

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) => const Stream.empty();

  @override
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) => throw UnimplementedError();

  @override
  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) => throw UnimplementedError();
}

class FakeFileSaveGateway implements FileSaveGateway {
  String? savedName;
  Uint8List? savedBytes;
  bool cancel = false;

  @override
  Future<Result<Unit, FileFailure>> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (cancel) return const Error(FileFailure(FileFailureKind.cancelled));
    savedName = fileName;
    savedBytes = bytes;
    return Success.unit();
  }
}
