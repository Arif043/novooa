import '../entities/knowledge_note_draft.dart';
import '../entities/knowledge_note.dart';

class KnowledgeNoteDraftFactory {
  const KnowledgeNoteDraftFactory();

  String newTitle(int existingNoteCount) {
    return 'Neue Notiz ${existingNoteCount + 1}';
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
