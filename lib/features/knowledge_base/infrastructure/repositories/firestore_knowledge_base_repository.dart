import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/infrastructure/repositories/team_workspace_bootstrapper.dart';

import '../../domain/entities/knowledge_failure.dart';
import '../../domain/entities/knowledge_note.dart';
import '../../domain/entities/knowledge_note_draft.dart';
import '../../domain/repositories/knowledge_base_repository.dart';
import '../models/knowledge_note_model.dart';

class FirestoreKnowledgeBaseRepository implements KnowledgeBaseRepository {
  FirestoreKnowledgeBaseRepository(this._firestore)
    : _bootstrapper = TeamWorkspaceBootstrapper(_firestore);

  final FirebaseFirestore _firestore;
  final TeamWorkspaceBootstrapper _bootstrapper;

  @override
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId) {
    return _notesReference(teamId).orderBy('title').snapshots().map(_notesFrom);
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> createNote({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  }) async {
    if (draft.title.trim().isEmpty) return _invalidTitle();
    try {
      await _bootstrapper.ensurePersonalTeam(
        teamId: teamId,
        ownerUid: ownerUid,
      );
      final noteId = UniqueId.random().value;
      await _notesReference(teamId).doc(noteId).set(_createDocument(draft));
      return _loadNote(teamId, noteId);
    } catch (_) {
      return const Error(KnowledgeFailure(KnowledgeFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> updateNote({
    required TeamId teamId,
    required String noteId,
    required KnowledgeNoteDraft draft,
  }) async {
    if (draft.title.trim().isEmpty) return _invalidTitle();
    try {
      await _notesReference(teamId).doc(noteId).update(_updateDocument(draft));
      return _loadNote(teamId, noteId);
    } catch (_) {
      return const Error(KnowledgeFailure(KnowledgeFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<Unit, KnowledgeFailure>> deleteNote({
    required TeamId teamId,
    required String noteId,
  }) async {
    try {
      await _notesReference(teamId).doc(noteId).delete();
      return const Success(unit);
    } catch (_) {
      return const Error(KnowledgeFailure(KnowledgeFailureKind.deleteFailed));
    }
  }

  List<KnowledgeNote> _notesFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(KnowledgeNoteModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  Future<Result<KnowledgeNote, KnowledgeFailure>> _loadNote(
    TeamId teamId,
    String noteId,
  ) async {
    final snapshot = await _notesReference(teamId).doc(noteId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return const Error(KnowledgeFailure(KnowledgeFailureKind.loadFailed));
    }
    return Success(KnowledgeNoteModel.fromDocument(snapshot).toDomain());
  }

  CollectionReference<Map<String, dynamic>> _notesReference(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('knowledgeBases')
        .doc('default')
        .collection('notes');
  }

  Map<String, Object?> _createDocument(KnowledgeNoteDraft draft) {
    return {..._noteDocument(draft), 'createdAt': FieldValue.serverTimestamp()};
  }

  Map<String, Object?> _updateDocument(KnowledgeNoteDraft draft) {
    return _noteDocument(draft);
  }

  Map<String, Object?> _noteDocument(KnowledgeNoteDraft draft) {
    return {
      'knowledgeBaseId': 'default',
      'title': draft.title.trim(),
      'path': draft.path.trim(),
      'content': draft.content,
      'type': draft.type.name,
      'outgoingLinks': draft.outgoingLinks,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Result<KnowledgeNote, KnowledgeFailure> _invalidTitle() {
    return const Error(KnowledgeFailure(KnowledgeFailureKind.invalidTitle));
  }
}
