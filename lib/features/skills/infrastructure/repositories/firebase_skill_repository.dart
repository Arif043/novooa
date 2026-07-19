import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_draft.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/repositories/skill_repository.dart';
import '../models/skill_model.dart';

/// Speichert Skill-Metadaten in Firestore und die zugehörige SKILL.md in
/// Firebase Storage. Der Storage-Pfad entspricht dem Ordner, den der
/// Backend-Runner in einen Node-Workspace mountet.
class FirebaseSkillRepository implements SkillRepository {
  const FirebaseSkillRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _skillFileName = 'SKILL.md';
  static const _skillContentType = 'text/markdown; charset=utf-8';

  @override
  Stream<List<Skill>> watchSkills(TeamId teamId) {
    return _skillsReference(teamId)
        .orderBy('title')
        .snapshots()
        .map(_skillsFrom);
  }

  @override
  Future<Result<Skill, SkillFailure>> loadSkillContent({
    required TeamId teamId,
    required String skillId,
  }) async {
    try {
      final snapshot = await _skillsReference(teamId).doc(skillId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return const Error(SkillFailure(SkillFailureKind.loadFailed));
      }
      final model = SkillModel.fromDocument(snapshot);
      final content = await _downloadContent(model.storagePath);
      return Success(model.toDomain(content: content));
    } catch (_) {
      return const Error(SkillFailure(SkillFailureKind.loadFailed));
    }
  }

  @override
  Future<Result<Skill, SkillFailure>> createSkill({
    required TeamId teamId,
    required SkillDraft draft,
  }) async {
    if (draft.title.trim().isEmpty) return _invalidTitle();
    try {
      final skillId = UniqueId.random().value;
      final storagePath = _storagePathFor(teamId, skillId);
      await _uploadContent(storagePath, draft.content);
      await _skillsReference(teamId).doc(skillId).set(
        _createDocument(draft: draft, storagePath: storagePath),
      );
      return _loadMetadata(teamId, skillId, draft.content);
    } catch (_) {
      return const Error(SkillFailure(SkillFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<Skill, SkillFailure>> updateSkill({
    required TeamId teamId,
    required String skillId,
    required SkillDraft draft,
  }) async {
    if (draft.title.trim().isEmpty) return _invalidTitle();
    try {
      final storagePath = _storagePathFor(teamId, skillId);
      await _uploadContent(storagePath, draft.content);
      await _skillsReference(teamId).doc(skillId).update(
        _updateDocument(draft: draft, storagePath: storagePath),
      );
      return _loadMetadata(teamId, skillId, draft.content);
    } catch (_) {
      return const Error(SkillFailure(SkillFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<Unit, SkillFailure>> deleteSkill({
    required TeamId teamId,
    required String skillId,
  }) async {
    try {
      final storagePath = _storagePathFor(teamId, skillId);
      await _skillsReference(teamId).doc(skillId).delete();
      await _deleteContent(storagePath);
      return const Success(unit);
    } catch (_) {
      return const Error(SkillFailure(SkillFailureKind.deleteFailed));
    }
  }

  List<Skill> _skillsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(SkillModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  Future<Result<Skill, SkillFailure>> _loadMetadata(
    TeamId teamId,
    String skillId,
    String content,
  ) async {
    final snapshot = await _skillsReference(teamId).doc(skillId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return const Error(SkillFailure(SkillFailureKind.loadFailed));
    }
    return Success(SkillModel.fromDocument(snapshot).toDomain(content: content));
  }

  CollectionReference<Map<String, dynamic>> _skillsReference(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value).collection('skills');
  }

  Map<String, Object?> _createDocument({
    required SkillDraft draft,
    required String storagePath,
  }) {
    return {
      ..._skillDocument(draft: draft, storagePath: storagePath),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _updateDocument({
    required SkillDraft draft,
    required String storagePath,
  }) {
    return _skillDocument(draft: draft, storagePath: storagePath);
  }

  Map<String, Object?> _skillDocument({
    required SkillDraft draft,
    required String storagePath,
  }) {
    return {
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'storagePath': storagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _storagePathFor(TeamId teamId, String skillId) {
    return 'teams/${teamId.value}/skills/$skillId/$_skillFileName';
  }

  Future<void> _uploadContent(String storagePath, String content) async {
    final data = Uint8List.fromList(utf8.encode(content));
    final metadata = SettableMetadata(contentType: _skillContentType);
    await _storage.ref(storagePath).putData(data, metadata);
  }

  Future<String> _downloadContent(String storagePath) async {
    if (storagePath.isEmpty) return '';
    try {
      final bytes = await _storage.ref(storagePath).getData();
      if (bytes == null) return '';
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  Future<void> _deleteContent(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // Der Metadaten-Delete ist bereits erfolgt; Storage-Reste sind harmlos.
    }
  }

  Result<Skill, SkillFailure> _invalidTitle() {
    return const Error(SkillFailure(SkillFailureKind.invalidTitle));
  }
}
