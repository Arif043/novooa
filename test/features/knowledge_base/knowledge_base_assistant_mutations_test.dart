import 'package:flutter_test/flutter_test.dart';
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
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_state.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  late _MemoryKnowledgeBaseRepository repository;
  late KnowledgeBaseCubit cubit;
  setUp(() {
    repository = _MemoryKnowledgeBaseRepository();
    cubit = KnowledgeBaseCubit(
      _AuthenticatedUserRepository(),
      WatchKnowledgeNotes(repository),
      CreateKnowledgeNote(repository),
      UpdateKnowledgeNote(repository),
      DeleteKnowledgeNote(repository),
      RestoreKnowledgeNote(repository),
      GetCurrentTeamId(_CurrentTeamRepository()),
    );
  });
  tearDown(() => cubit.close());
  test('erstellt einen vom Agenten vorgeschlagenen Eintrag', () async {
    final note = await cubit.createSuggestedNote(
      title: 'Projektstart',
      content: '# Projektstart',
    );
    expect(note.title, 'Projektstart');
    expect(cubit.state.notes.single.content, '# Projektstart');
  });
  test('bearbeitet einen vom Agenten vorgeschlagenen Eintrag', () async {
    final original = await cubit.createSuggestedNote(
      title: 'Alt',
      content: 'Vorher',
    );
    final updated = await cubit.updateSuggestedNote(
      noteId: original.id,
      title: 'Neu',
      content: 'Nachher',
    );
    expect(updated.title, 'Neu');
    expect(cubit.state.notes.single.content, 'Nachher');
  });
  test('löscht einen vom Agenten vorgeschlagenen Eintrag', () async {
    final note = await cubit.createSuggestedNote(title: 'Löschen', content: '');
    await cubit.deleteSuggestedNote(note.id);
    expect(cubit.state.notes, isEmpty);
  });

  test('stellt einen gelöschten Eintrag für Rückgängig wieder her', () async {
    final note = await cubit.createSuggestedNote(
      title: 'Wiederherstellen',
      content: 'Inhalt',
    );
    await cubit.deleteSuggestedNote(note.id);
    await cubit.restoreSuggestedNote(note);
    expect(cubit.state.notes.single.id, note.id);
    expect(cubit.state.notes.single.content, 'Inhalt');
  });

  test('speichert automatisch ohne Erfolgsmeldung', () async {
    final note = await cubit.createSuggestedNote(title: 'Notiz', content: '');
    cubit.selectNote(note.id);
    cubit.updateContent('Neuer Inhalt');
    expect(cubit.state.isSaving, isTrue);

    await Future<void>.delayed(
      KnowledgeBaseCubit.saveDelay + const Duration(milliseconds: 50),
    );

    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.message, isNull);
    expect(cubit.state.status, KnowledgeBaseStatus.ready);
  });
}

class _MemoryKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Map<String, KnowledgeNote> _notes = {};
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

class _AuthenticatedUserRepository implements AuthRepository {
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

class _CurrentTeamRepository implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team.1');
}
