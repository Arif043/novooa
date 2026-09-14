import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/workspace_api_client.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/knowledge_failure.dart';
import '../../domain/entities/knowledge_note.dart';
import '../../domain/entities/knowledge_note_draft.dart';
import '../../domain/repositories/knowledge_base_repository.dart';

class LocalKnowledgeBaseRepository implements KnowledgeBaseRepository {
  const LocalKnowledgeBaseRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> createNote({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  }) async {
    if (draft.title.trim().isEmpty) return _invalidTitle();
    try {
      return Success(
        _noteFrom(await _client.post('/v1/knowledge-notes', _body(draft))),
      );
    } on Object {
      return _saveFailure();
    }
  }

  @override
  Future<Result<Unit, KnowledgeFailure>> deleteNote({
    required TeamId teamId,
    required String noteId,
  }) async {
    try {
      await _client.delete('/v1/knowledge-notes/$noteId');
      return const Success(unit);
    } on Object {
      return const Error(KnowledgeFailure(KnowledgeFailureKind.deleteFailed));
    }
  }

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> restoreNote({
    required TeamId teamId,
    required KnowledgeNote note,
  }) => _save(note.id, _bodyFromNote(note));

  @override
  Future<Result<KnowledgeNote, KnowledgeFailure>> updateNote({
    required TeamId teamId,
    required String noteId,
    required KnowledgeNoteDraft draft,
  }) {
    if (draft.title.trim().isEmpty) return Future.value(_invalidTitle());
    return _save(noteId, _body(draft));
  }

  @override
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId) =>
      pollWorkspace(_loadNotes);

  Future<List<KnowledgeNote>> _loadNotes() async {
    final response = await _client.get('/v1/knowledge-notes');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Wissensbasis ist ungültig.');
    }
    return items.whereType<Map>().map(_noteFrom).toList(growable: false);
  }

  Future<Result<KnowledgeNote, KnowledgeFailure>> _save(
    String noteId,
    Map<String, Object?> body,
  ) async {
    try {
      return Success(
        _noteFrom(await _client.put('/v1/knowledge-notes/$noteId', body)),
      );
    } on Object {
      return _saveFailure();
    }
  }

  Map<String, Object?> _body(KnowledgeNoteDraft draft) => {
    'knowledgeBaseId': 'default',
    'title': draft.title.trim(),
    'path': draft.path.trim(),
    'content': draft.content,
    'outgoingLinks': draft.outgoingLinks,
  };

  Map<String, Object?> _bodyFromNote(KnowledgeNote note) => {
    'knowledgeBaseId': note.knowledgeBaseId,
    'title': note.title,
    'path': note.path,
    'content': note.content,
    'outgoingLinks': note.outgoingLinks,
  };

  KnowledgeNote _noteFrom(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return KnowledgeNote(
      id: _string(data['id']),
      knowledgeBaseId: _string(data['knowledgeBaseId'], fallback: 'default'),
      title: _string(data['title'], fallback: 'Unbenannte Notiz'),
      path: _string(data['path']),
      content: _string(data['content']),
      outgoingLinks: _strings(data['outgoingLinks']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  DateTime _date(Object? value) => value is String
      ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.fromMillisecondsSinceEpoch(0);

  String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  Result<KnowledgeNote, KnowledgeFailure> _invalidTitle() =>
      const Error(KnowledgeFailure(KnowledgeFailureKind.invalidTitle));

  Result<KnowledgeNote, KnowledgeFailure> _saveFailure() =>
      const Error(KnowledgeFailure(KnowledgeFailureKind.saveFailed));
}
