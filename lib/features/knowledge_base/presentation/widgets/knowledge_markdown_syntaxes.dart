import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_footnotes.dart';
import 'knowledge_wiki_link_syntax.dart';

const knowledgeHighlightTag = 'mark';
const knowledgeMathTag = 'latex';
const knowledgeMathStyleAttribute = 'MathStyle';

/// `==markiert==` wie in Obsidian.
class KnowledgeHighlightSyntax extends md.DelimiterSyntax {
  KnowledgeHighlightSyntax()
      : super(
          '=+',
          requiresDelimiterRun: true,
          allowIntraWord: true,
          startCharacter: '='.codeUnitAt(0),
          tags: [md.DelimiterTag(knowledgeHighlightTag, 2)],
        );
}

/// `$$Formel$$` und `$Formel$` im Fließtext.
///
/// Wie in Obsidian und Pandoc darf direkt nach dem öffnenden und vor dem
/// schließenden `$` kein Leerzeichen stehen, und auf das schließende `$` folgt
/// keine Ziffer — so bleiben Beträge wie „5 $ bis 10 $“ normaler Text.
class KnowledgeInlineMathSyntax extends md.InlineSyntax {
  KnowledgeInlineMathSyntax()
      : super(_pattern, startCharacter: r'$'.codeUnitAt(0));

  static const _pattern =
      r'\$\$([^$\n]+?)\$\$|\$(?!\s)([^$\n]+?)(?<!\s)\$(?!\d)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final display = match[1] != null;
    final tex = (match[1] ?? match[2]!).trim();
    parser.addNode(md.Element.text(knowledgeMathTag, tex)
      ..attributes[knowledgeMathStyleAttribute] = display ? 'display' : 'text');
    return true;
  }
}

/// Block-Syntaxen ohne Fußnoten-Definitionen; diese löst
/// [KnowledgeFootnoteDefinitionSyntax] aus dem Text.
List<md.BlockSyntax> knowledgeBlockSyntaxes() {
  return [
    LatexBlockSyntax(),
    ...md.ExtensionSet.gitHubFlavored.blockSyntaxes
        .where((syntax) => syntax is! md.FootnoteDefSyntax),
  ];
}

/// GitHub-Flavored-Markdown plus Wiki-Links, Fußnoten, Formeln, Markierung und
/// Emoji-Kürzel.
md.ExtensionSet knowledgeExtensionSet({
  required List<KnowledgeNote> notes,
  required KnowledgeFootnotes footnotes,
}) {
  return md.ExtensionSet(
    [KnowledgeFootnoteDefinitionSyntax(), ...knowledgeBlockSyntaxes()],
    [
      KnowledgeWikiLinkSyntax(notes: notes),
      KnowledgeFootnoteReferenceSyntax(footnotes),
      KnowledgeInlineMathSyntax(),
      KnowledgeHighlightSyntax(),
      md.EmojiSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
    ],
  );
}
