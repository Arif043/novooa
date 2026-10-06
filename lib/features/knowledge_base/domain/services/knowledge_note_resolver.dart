import '../entities/knowledge_note.dart';

/// Ordnet ein Linkziel (Wiki-Link oder Markdown-Link) einer Notiz zu.
///
/// Eine Notiz ist über ihre ID, ihren Titel und ihren Pfad — mit oder ohne
/// `.md` — erreichbar; Groß- und Kleinschreibung zählt nicht.
class KnowledgeNoteResolver {
  const KnowledgeNoteResolver();

  KnowledgeNote? resolve(String target, List<KnowledgeNote> notes) {
    final normalizedTarget = _normalized(target);
    if (normalizedTarget.isEmpty) return null;
    for (final note in notes) {
      if (aliasesFor(note).contains(normalizedTarget)) return note;
    }
    return null;
  }

  Set<String> aliasesFor(KnowledgeNote note) {
    return {
      note.id,
      note.title,
      note.path,
      _withoutMarkdownExtension(note.path),
    }.map(_normalized).where((alias) => alias.isNotEmpty).toSet();
  }

  String _normalized(String value) => value.trim().toLowerCase();

  String _withoutMarkdownExtension(String path) {
    return path.endsWith('.md') ? path.substring(0, path.length - 3) : path;
  }
}
