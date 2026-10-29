import '../entities/knowledge_note_draft.dart';
import '../entities/knowledge_note.dart';
import 'knowledge_note_titles.dart';

class KnowledgeNoteDraftFactory {
  const KnowledgeNoteDraftFactory();

  /// Der erste freie Name „Neue Notiz n“ — nach Löschungen kann `Anzahl + 1`
  /// schon vergeben sein.
  String newTitle(List<KnowledgeNote> existingNotes) {
    for (var number = 1; ; number++) {
      final title = 'Neue Notiz $number';
      if (!isKnowledgeNoteTitleTaken(existingNotes, title)) return title;
    }
  }

  KnowledgeNoteDraft create({
    required String title,
    String? path,
    String content = '',
    List<String> outgoingLinks = const [],
  }) {
    return KnowledgeNoteDraft(
      title: title,
      path: path ?? pathFor(title),
      content: content,
      outgoingLinks: outgoingLinks,
    );
  }

  KnowledgeNoteDraft fromNote(KnowledgeNote note) {
    return create(
      title: note.title,
      path: note.path,
      content: note.content,
      outgoingLinks: note.outgoingLinks,
    );
  }

  String pathFor(String title) {
    final slug = title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return '${slug.isEmpty ? 'notiz' : slug}.md';
  }
}
