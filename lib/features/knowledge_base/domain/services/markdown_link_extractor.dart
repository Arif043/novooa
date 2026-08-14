import '../entities/knowledge_note.dart';
import 'wiki_link_parser.dart';

class MarkdownLinkExtractor {
  const MarkdownLinkExtractor([this._wikiLinkParser = const WikiLinkParser()]);

  final WikiLinkParser _wikiLinkParser;

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
    final aliases = _aliasesFor(note);
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

  Set<String> _aliasesFor(KnowledgeNote note) {
    return {
          note.id,
          note.title,
          note.path,
          _withoutMarkdownExtension(note.path),
        }
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  String _withoutMarkdownExtension(String path) {
    return path.endsWith('.md') ? path.substring(0, path.length - 3) : path;
  }
}
