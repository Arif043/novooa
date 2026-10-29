import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_failure.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note_draft.dart';
import 'package:syscat2/features/knowledge_base/domain/repositories/knowledge_base_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/create_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/delete_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/restore_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/update_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

/// Cubit mit Wissensbasis im Speicher; [repository] zeigt, was gespeichert wurde.
KnowledgeBaseCubit memoryKnowledgeBaseCubit(
  MemoryKnowledgeBaseRepository repository,
) {
  return KnowledgeBaseCubit(
    AuthenticatedUserRepository(),
    WatchKnowledgeNotes(repository),
    CreateKnowledgeNote(repository),
    UpdateKnowledgeNote(repository),
    DeleteKnowledgeNote(repository),
    RestoreKnowledgeNote(repository),
    GetCurrentTeamId(CurrentTeamRepository()),
  );
}

class MemoryKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Map<String, KnowledgeNote> _notes = {};

  /// Wie oft gespeichert wurde (Anlegen ausgenommen).
  var updates = 0;
  var _nextId = 1;

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> createNote({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  }) async {
    final note = _noteFor('note.${_nextId++}', draft);
    _notes[note.id] = note;
    return Success(note);
  }

  @override
  Future<Result<Unit, KnowledgeFailure>> deleteNote({
    required TeamId teamId,
    required String noteId,
  }) async {
    _notes.remove(noteId);
    return const Success(unit);
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> restoreNote({
    required TeamId teamId,
    required KnowledgeNote note,
  }) async {
    _notes[note.id] = note;
    return Success(note);
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> updateNote({
    required TeamId teamId,
    required String noteId,
    required KnowledgeNoteDraft draft,
  }) async {
    updates++;
    final note = _noteFor(noteId, draft);
    _notes[noteId] = note;
    return Success(note);
  }

  @override
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId) {
    return Stream.value(_notes.values.toList());
  }

  KnowledgeNote _noteFor(String id, KnowledgeNoteDraft draft) {
    return KnowledgeNote(
      id: id,
      knowledgeBaseId: 'default',
      title: draft.title,
      path: draft.path,
      content: draft.content,
      outgoingLinks: draft.outgoingLinks,
      updatedAt: DateTime(2026),
    );
  }
}

class AuthenticatedUserRepository implements AuthRepository {
  @override
  AuthUser? currentUser() {
    return const AuthUser(
      id: UniqueId('user.1'),
      email: 'ada@example.com',
      displayName: 'Ada',
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser());
}

class CurrentTeamRepository implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team.1');
}
