import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/repositories/team_file_repository.dart';
import '../models/team_file_model.dart';
import '../models/team_folder_model.dart';
import 'team_workspace_bootstrapper.dart';
import 'versioned_file_ids.dart';

class FirebaseTeamFileRepository implements TeamFileRepository {
  FirebaseTeamFileRepository(this._firestore, this._storage)
    : _bootstrapper = TeamWorkspaceBootstrapper(_firestore);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final TeamWorkspaceBootstrapper _bootstrapper;

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
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
    required String? folderId,
  }) async {
    try {
      final ids = VersionedFileIds();
      await _bootstrapper.ensurePersonalTeam(
        teamId: teamId,
        ownerUid: ownerUid,
      );
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
      await _bootstrapper.ensurePersonalTeam(
        teamId: teamId,
        ownerUid: ownerUid,
      );
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
