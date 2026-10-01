import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/repositories/team_file_repository.dart';
import '../../domain/repositories/file_version_repository.dart';
import '../models/file_version_model.dart';
import '../models/team_file_model.dart';
import '../models/team_folder_model.dart';
import 'versioned_file_ids.dart';

class FirebaseTeamFileRepository
    implements TeamFileRepository, FileVersionRepository {
  const FirebaseTeamFileRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<TeamFile>> watchFiles(TeamId teamId) {
    return _filesReference(
      teamId,
    ).orderBy('updatedAt', descending: true).snapshots().map(_toFiles);
  }

  @override
  Stream<List<TeamFolder>> watchFolders(TeamId teamId) {
    return _foldersReference(
      teamId,
    ).orderBy('name').snapshots().map(_toFolders);
  }

  @override
  Stream<List<FileVersion>> watchVersions(TeamId teamId, String fileId) {
    return _filesReference(teamId)
        .doc(fileId)
        .collection('versions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => FileVersionModel.fromDocument(document, teamId),
              )
              .map((model) => model.toDomain())
              .toList(growable: false),
        );
  }

  @override
  Future<Result<Uint8List, FileFailure>> downloadVersion(
    FileVersion version,
  ) async {
    try {
      final bytes = await _storage
          .ref()
          .child(version.storagePath)
          .getData(5 * 1024 * 1024);
      if (bytes == null) {
        return const Error(FileFailure(FileFailureKind.downloadFailed));
      }
      return Success(bytes);
    } catch (_) {
      return const Error(FileFailure(FileFailureKind.downloadFailed));
    }
  }

  @override
  Future<Result<TeamFile, FileFailure>> createVersion({
    required TeamFile file,
    required String ownerUid,
    required UploadFileInput input,
  }) async {
    try {
      final ids = VersionedFileIds.existing(file.id);
      final storagePath = _storagePath(file.teamId, ids, input);
      await _storage
          .ref()
          .child(storagePath)
          .putData(input.bytes, _metadata(input));
      await _writeVersionMetadata(file, ownerUid, input, ids, storagePath);
      final snapshot = await _filesReference(file.teamId).doc(file.id).get();
      return Success(TeamFileModel.fromDocument(snapshot).toDomain());
    } catch (_) {
      return const Error(FileFailure(FileFailureKind.uploadFailed));
    }
  }

  @override
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) async {
    try {
      final ids = VersionedFileIds();
      final storagePath = _storagePath(teamId, ids, input);
      final reference = _storage.ref().child(storagePath);
      await reference.putData(input.bytes, _metadata(input));
      await _writeMetadata(teamId, ownerUid, input, ids, storagePath, folderId);
      final snapshot = await _filesReference(teamId).doc(ids.fileId).get();
      return Success(TeamFileModel.fromDocument(snapshot).toDomain());
    } catch (_) {
      return const Error(FileFailure(FileFailureKind.uploadFailed));
    }
  }

  /// Löschen ist bisher nur in der lokalen Runtime umgesetzt: Dort entfernt
  /// der Server Metadaten und Dateiinhalt gemeinsam und löst das Ereignis
  /// „Datei gelöscht" aus. Ein clientseitiges Löschen in Firestore würde die
  /// Inhalte im Storage zurücklassen.
  @override
  Future<Result<Unit, FileFailure>> deleteFile({
    required TeamId teamId,
    required String fileId,
  }) async {
    return const Error(FileFailure(FileFailureKind.deleteFailed));
  }

  @override
  Future<Result<TeamFolder, FileFailure>> createFolder({
    required TeamId teamId,
    required String ownerUid,
    required String name,
    required String? parentFolderId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Error(FileFailure(FileFailureKind.invalidFolderName));
    }
    try {
      final folderId = UniqueId.random().value;
      await _foldersReference(teamId).doc(folderId).set({
        'id': folderId,
        'teamId': teamId.value,
        'ownerUid': ownerUid,
        'name': trimmedName,
        'parentFolderId': parentFolderId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await _foldersReference(teamId).doc(folderId).get();
      return Success(TeamFolderModel.fromDocument(snapshot).toDomain());
    } catch (_) {
      return const Error(FileFailure(FileFailureKind.createFolderFailed));
    }
  }

  List<TeamFile> _toFiles(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(TeamFileModel.fromDocument)
        .map((e) => e.toDomain())
        .toList(growable: false);
  }

  List<TeamFolder> _toFolders(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(TeamFolderModel.fromDocument)
        .map((e) => e.toDomain())
        .toList(growable: false);
  }

  Future<void> _writeMetadata(
    TeamId teamId,
    String ownerUid,
    UploadFileInput input,
    VersionedFileIds ids,
    String storagePath,
    String? folderId,
  ) async {
    final batch = _firestore.batch();
    batch.set(_filesReference(teamId).doc(ids.fileId), {
      ..._fileDocument(teamId, ownerUid, input, ids, storagePath, folderId),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_versionReference(teamId, ids), {
      ..._versionDocument(ownerUid, input, ids, storagePath),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> _writeVersionMetadata(
    TeamFile file,
    String ownerUid,
    UploadFileInput input,
    VersionedFileIds ids,
    String storagePath,
  ) async {
    final batch = _firestore.batch();
    batch.update(_filesReference(file.teamId).doc(file.id), {
      'storagePath': storagePath,
      'currentVersionId': ids.versionId,
      'contentType': input.contentType ?? file.contentType,
      'sizeBytes': input.sizeBytes,
      'currentVersionCreatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_versionReference(file.teamId, ids), {
      ..._versionDocument(ownerUid, input, ids, storagePath),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Map<String, Object?> _fileDocument(
    TeamId teamId,
    String ownerUid,
    UploadFileInput input,
    VersionedFileIds ids,
    String storagePath,
    String? folderId,
  ) {
    return {
      'teamId': teamId.value,
      'ownerUid': ownerUid,
      'displayName': input.name,
      'folderId': folderId,
      'storagePath': storagePath,
      'currentVersionId': ids.versionId,
      'contentType': input.contentType ?? 'application/octet-stream',
      'sizeBytes': input.sizeBytes,
      'currentVersionCreatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _versionDocument(
    String ownerUid,
    UploadFileInput input,
    VersionedFileIds ids,
    String storagePath,
  ) {
    return {
      'id': ids.versionId,
      'fileId': ids.fileId,
      'createdByUid': ownerUid,
      'displayName': input.name,
      'storagePath': storagePath,
      'contentType': input.contentType ?? 'application/octet-stream',
      'sizeBytes': input.sizeBytes,
    };
  }

  SettableMetadata _metadata(UploadFileInput input) {
    return SettableMetadata(contentType: input.contentType);
  }

  CollectionReference<Map<String, dynamic>> _filesReference(TeamId teamId) {
    return _teamReference(teamId).collection('files');
  }

  CollectionReference<Map<String, dynamic>> _foldersReference(TeamId teamId) {
    return _teamReference(teamId).collection('folders');
  }

  DocumentReference<Map<String, dynamic>> _teamReference(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value);
  }

  DocumentReference<Map<String, dynamic>> _versionReference(
    TeamId teamId,
    VersionedFileIds ids,
  ) {
    return _filesReference(
      teamId,
    ).doc(ids.fileId).collection('versions').doc(ids.versionId);
  }

  String _storagePath(
    TeamId teamId,
    VersionedFileIds ids,
    UploadFileInput input,
  ) {
    return 'teams/${teamId.value}/files/${ids.fileId}/versions/${ids.versionId}/${input.name}';
  }
}
