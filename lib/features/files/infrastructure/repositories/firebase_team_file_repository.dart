import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';

import '../../domain/entities/file_failure.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/repositories/team_file_repository.dart';
import '../models/team_file_model.dart';

class FirebaseTeamFileRepository implements TeamFileRepository {
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
  Future<Result<TeamFile, FileFailure>> uploadFile({
    required TeamId teamId,
    required String ownerUid,
    required UploadFileInput input,
  }) async {
    try {
      final ids = _VersionedFileIds();
      await _ensurePersonalTeam(teamId: teamId, ownerUid: ownerUid);
      final storagePath = _storagePath(
        teamId,
        ids.fileId,
        ids.versionId,
        input,
      );
      final reference = _storage.ref().child(storagePath);
      await reference.putData(input.bytes, _metadata(input));
      await _writeMetadata(teamId, ownerUid, input, ids, storagePath);
      final snapshot = await _filesReference(teamId).doc(ids.fileId).get();
      return Success(TeamFileModel.fromDocument(snapshot).toDomain());
    } catch (_) {
      return const Error(FileFailure(FileFailureKind.uploadFailed));
    }
  }

  List<TeamFile> _toFiles(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(TeamFileModel.fromDocument)
        .map((e) {
          return e.toDomain();
        })
        .toList(growable: false);
  }

  Future<void> _ensurePersonalTeam({
    required TeamId teamId,
    required String ownerUid,
  }) async {
    final batch = _firestore.batch();
    batch.set(
      _teamReference(teamId),
      _teamDocument(ownerUid),
      SetOptions(merge: true),
    );
    batch.set(
      _memberReference(teamId, ownerUid),
      _memberDocument(ownerUid),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> _writeMetadata(
    TeamId teamId,
    String ownerUid,
    UploadFileInput input,
    _VersionedFileIds ids,
    String storagePath,
  ) async {
    final batch = _firestore.batch();
    batch.set(_filesReference(teamId).doc(ids.fileId), {
      ..._fileDocument(teamId, ownerUid, input, ids, storagePath),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_versionReference(teamId, ids), {
      ..._versionDocument(ownerUid, input, ids, storagePath),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Map<String, Object?> _teamDocument(String ownerUid) {
    return {
      'ownerUid': ownerUid,
      'name': 'Persönlicher Arbeitsbereich',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _memberDocument(String ownerUid) {
    return {
      'uid': ownerUid,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _fileDocument(
    TeamId teamId,
    String ownerUid,
    UploadFileInput input,
    _VersionedFileIds ids,
    String storagePath,
  ) {
    return {
      'teamId': teamId.value,
      'ownerUid': ownerUid,
      'displayName': input.name,
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
    _VersionedFileIds ids,
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

  DocumentReference<Map<String, dynamic>> _teamReference(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value);
  }

  DocumentReference<Map<String, dynamic>> _memberReference(
    TeamId teamId,
    String ownerUid,
  ) {
    return _teamReference(teamId).collection('members').doc(ownerUid);
  }

  DocumentReference<Map<String, dynamic>> _versionReference(
    TeamId teamId,
    _VersionedFileIds ids,
  ) {
    return _filesReference(
      teamId,
    ).doc(ids.fileId).collection('versions').doc(ids.versionId);
  }

  String _storagePath(
    TeamId teamId,
    String fileId,
    String versionId,
    UploadFileInput input,
  ) {
    return 'teams/${teamId.value}/files/$fileId/versions/$versionId/${input.name}';
  }
}

class _VersionedFileIds {
  _VersionedFileIds()
    : fileId = UniqueId.random().value,
      versionId = UniqueId.random().value;

  final String fileId;
  final String versionId;
}
