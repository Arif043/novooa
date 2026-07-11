import 'knowledge_note.dart';

class KnowledgeNoteDraft {
  const KnowledgeNoteDraft({
    required this.title,
    required this.path,
    required this.content,
    required this.type,
    required this.outgoingLinks,
  });

  final String title;
  final String path;
  final String content;
  final KnowledgeNoteType type;
  final List<String> outgoingLinks;
}
