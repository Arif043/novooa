import '../entities/knowledge_note.dart';
import 'knowledge_note_resolver.dart';
import 'wiki_link_parser.dart';

class MarkdownLinkExtractor {
  const MarkdownLinkExtractor([
    this._wikiLinkParser = const WikiLinkParser(),
    this._noteResolver = const KnowledgeNoteResolver(),
  ]);

  final WikiLinkParser _wikiLinkParser;
  final KnowledgeNoteResolver _noteResolver;

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
    final aliases = _noteResolver.aliasesFor(note);
    final normalizedContent = content.toLowerCase();
    final wikiTargets = _wikiLinkParser(
      content,
    ).map((link) => link.target.trim().toLowerCase()).toSet();
    return aliases.any((alias) {
      return normalizedContent.contains(']($alias)') ||
          normalizedContent.contains('](${Uri.encodeComponent(alias)})') ||
          wikiTargets.contains(alias);
    });
  }
}
