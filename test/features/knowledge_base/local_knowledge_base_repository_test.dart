import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_failure.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note_draft.dart';
import 'package:syscat2/features/knowledge_base/infrastructure/repositories/local_knowledge_base_repository.dart';

void main() {
  const teamId = TeamId('team.1');
  const draft = KnowledgeNoteDraft(
    title: 'Fristen',
    path: 'fristen.md',
    content: '',
    outgoingLinks: [],
  );

  test(
    'ein vergebener Titel wird beim Anlegen und Speichern erkannt',
    () async {
      final repository = LocalKnowledgeBaseRepository(
        _FailingApi(_duplicateTitle()),
        _FakeChannel(),
      );

      final created = await repository.createNote(
        teamId: teamId,
        ownerUid: 'user.1',
        draft: draft,
      );
      final updated = await repository.updateNote(
        teamId: teamId,
        noteId: 'note.1',
        draft: draft,
      );

      expect(created.tryGetError()?.kind, KnowledgeFailureKind.duplicateTitle);
      expect(updated.tryGetError()?.kind, KnowledgeFailureKind.duplicateTitle);
    },
  );

  test('andere Fehler bleiben ein allgemeiner Speicherfehler', () async {
    final repository = LocalKnowledgeBaseRepository(
      _FailingApi(StateError('Netz weg')),
      _FakeChannel(),
    );

    final created = await repository.createNote(
      teamId: teamId,
      ownerUid: 'user.1',
      draft: draft,
    );

    expect(created.tryGetError()?.kind, KnowledgeFailureKind.saveFailed);
  });
}

WorkspaceHttpException _duplicateTitle() => WorkspaceHttpException(
  409,
  const WorkspaceApiError(
    message: 'Eine Notiz mit dem Titel „Fristen“ gibt es schon.',
    code: 'duplicate_title',
  ),
);

class _FailingApi implements WorkspaceApiClient {
  _FailingApi(this.failure);

  final Object failure;

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) =>
      Future.error(failure);

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      Future.error(failure);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeChannel implements WorkspaceRealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
