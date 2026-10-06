import 'package:markdown/markdown.dart' as md;

import '../../domain/entities/knowledge_note.dart';
import '../../domain/services/knowledge_note_resolver.dart';
import '../../domain/services/wiki_link_parser.dart';

/// Schema für Links, die innerhalb der Wissensbasis eine Notiz öffnen.
const knowledgeNoteLinkScheme = 'novooa-note';

String knowledgeNoteHref(String noteId) => '$knowledgeNoteLinkScheme:$noteId';

/// Rendert `[[Ziel]]` und `[[Ziel|Beschriftung]]` als Link auf die Notiz.
///
/// Wiki-Links ohne passende Notiz bleiben als Text stehen, damit erkennbar
/// ist, dass ihr Ziel fehlt.
class KnowledgeWikiLinkSyntax extends md.InlineSyntax {
  KnowledgeWikiLinkSyntax({
    required this.notes,
    this.parser = const WikiLinkParser(),
    this.resolver = const KnowledgeNoteResolver(),
  }) : super(_pattern, startCharacter: _openingBracket);

  final List<KnowledgeNote> notes;
  final WikiLinkParser parser;
  final KnowledgeNoteResolver resolver;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_nodeFor(match.group(0)!));
    return true;
  }

  md.Node _nodeFor(String source) {
    final links = parser(source);
    if (links.isEmpty) return md.Text(source);
    final link = links.single;
    final note = resolver.resolve(link.target, notes);
    if (note == null) return md.Text(source);
    return md.Element.text('a', link.label)
      ..attributes['href'] = knowledgeNoteHref(note.id)
      ..attributes['title'] = note.title;
  }
}

const _pattern = r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]';
final _openingBracket = '['.codeUnitAt(0);
