import '../entities/knowledge_note.dart';

class MarkdownLinkExtractor {
  const MarkdownLinkExtractor();

  List<String> call({
    required String content,
    required List<KnowledgeNote> notes,
  }) {
    final linkedIds = <String>{};
    for (final note in notes) {
      if (_referencesNote(content, note)) linkedIds.add(note.id);
    }
    return linkedIds.toList(growable: false);
  }

  bool _referencesNote(String content, KnowledgeNote note) {
    final aliases = {note.id, note.title, note.path}.where((value) {
      return value.trim().isNotEmpty;
    });
    return aliases.any((alias) {
      return content.contains('[[$alias]]') ||
          content.contains(']($alias)') ||
          content.contains('](${Uri.encodeComponent(alias)})');
    });
  }
}
