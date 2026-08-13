import 'package:firebase_ai/firebase_ai.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

class FirebaseAiKnowledgeBaseReadTools {
  FirebaseAiKnowledgeBaseReadTools({
    required AuthRepository authRepository,
    required WatchKnowledgeNotes watchKnowledgeNotes,
    required GetCurrentTeamId getCurrentTeamId,
  }) : this._(authRepository, watchKnowledgeNotes, getCurrentTeamId);

  FirebaseAiKnowledgeBaseReadTools._(
    this._authRepository,
    this._watchKnowledgeNotes,
    this._getCurrentTeamId,
  );

  final AuthRepository _authRepository;
  final WatchKnowledgeNotes _watchKnowledgeNotes;
  final GetCurrentTeamId _getCurrentTeamId;

  Tool get tool => Tool.functionDeclarations([
    AutoFunctionDeclaration(
      name: 'searchKnowledgeNotes',
      description: 'Durchsucht Notizen der aktuellen teamweiten Wissensbasis.',
      parameters: {
        'query': Schema.string(
          description: 'Suchbegriff; leer listet Notizen.',
        ),
      },
      optionalParameters: const ['query'],
      callable: _search,
    ),
    AutoFunctionDeclaration(
      name: 'readKnowledgeNote',
      description: 'Liest den Markdown-Inhalt einer Notiz anhand ihrer ID.',
      parameters: {
        'noteId': Schema.string(description: 'Die ID der zu lesenden Notiz.'),
      },
      callable: _read,
    ),
  ]);

  Future<Map<String, Object?>> _search(Map<String, Object?> arguments) async {
    final notes = await _notesForCurrentUser();
    final query = _text(arguments['query']).toLowerCase();
    final matches = notes.where((note) => _matches(note, query)).take(20);
    return {'notes': matches.map(_summaryFor).toList(growable: false)};
  }

  Future<Map<String, Object?>> _read(Map<String, Object?> arguments) async {
    final noteId = _text(arguments['noteId']);
    if (noteId.isEmpty) return {'error': 'Eine Notiz-ID fehlt.'};
    final notes = await _notesForCurrentUser();
    final note = _noteWithId(notes, noteId);
    if (note == null) return {'error': 'Die Notiz wurde nicht gefunden.'};
    return {
      'id': note.id,
      'title': note.title,
      'path': note.path,
      'content': _limitedContent(note.content),
    };
  }

  Future<List<KnowledgeNote>> _notesForCurrentUser() async {
    if (_authRepository.currentUser() == null) {
      throw StateError('Du musst angemeldet sein.');
    }
    final teamId = await _getCurrentTeamId();
    return _watchKnowledgeNotes(teamId).first;
  }

  bool _matches(KnowledgeNote note, String query) {
    if (query.isEmpty) return true;
    final searchable = '${note.title}\n${note.path}\n${note.content}'
        .toLowerCase();
    return searchable.contains(query);
  }

  Map<String, Object?> _summaryFor(KnowledgeNote note) {
    return {
      'id': note.id,
      'title': note.title,
      'path': note.path,
      'excerpt': _limitedContent(note.content, limit: 700),
    };
  }

  KnowledgeNote? _noteWithId(List<KnowledgeNote> notes, String noteId) {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }
}

String _text(Object? value) {
  return value is String ? value.trim() : '';
}

String _limitedContent(String content, {int limit = 12000}) {
  if (content.length <= limit) return content;
  return '${content.substring(0, limit)}\n\n[Inhalt gekürzt]';
}
