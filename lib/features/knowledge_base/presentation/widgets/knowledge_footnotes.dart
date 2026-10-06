import 'package:markdown/markdown.dart' as md;

/// Eine Fußnote der Notiz: Nummer in Reihenfolge der Definition und ihr
/// Markdown-Text.
class KnowledgeFootnote {
  const KnowledgeFootnote({
    required this.label,
    required this.number,
    required this.markdown,
  });

  final String label;
  final int number;
  final String markdown;
}

const _footnoteHrefPrefix = '#fn-';

String knowledgeFootnoteHref(String label) => '$_footnoteHrefPrefix$label';

/// Liefert das Label, wenn [href] auf eine Fußnote zeigt.
String? knowledgeFootnoteLabelOf(String href) {
  if (!href.startsWith(_footnoteHrefPrefix)) return null;
  return href.substring(_footnoteHrefPrefix.length);
}

/// Die Fußnoten einer Notiz. Ihre Definitionen (`[^1]: Text`) werden aus dem
/// Fließtext gelöst und als eigener Abschnitt gerendert, damit Verweise und
/// Rücksprünge ein Ziel haben.
class KnowledgeFootnotes {
  const KnowledgeFootnotes(this.all);

  static const empty = KnowledgeFootnotes([]);

  final List<KnowledgeFootnote> all;

  bool get isEmpty => all.isEmpty;

  KnowledgeFootnote? byLabel(String label) {
    for (final footnote in all) {
      if (footnote.label == label) return footnote;
    }
    return null;
  }

  /// Liest die Definitionen mit denselben Block-Regeln wie das Rendering, damit
  /// `[^1]:` in Codeblöcken nicht als Fußnote gilt.
  static KnowledgeFootnotes extract(
    String content,
    List<md.BlockSyntax> otherBlockSyntaxes,
  ) {
    final collector = KnowledgeFootnoteDefinitionSyntax();
    md.Document(
      blockSyntaxes: [collector, ...otherBlockSyntaxes],
      encodeHtml: false,
    ).parseLines(content.split('\n'));
    return KnowledgeFootnotes(collector.collected);
  }
}

/// Löst Fußnoten-Definitionen aus dem Fließtext und merkt sich ihren Text.
class KnowledgeFootnoteDefinitionSyntax extends md.FootnoteDefSyntax {
  KnowledgeFootnoteDefinitionSyntax();

  final List<KnowledgeFootnote> collected = [];

  @override
  md.Node? parse(md.BlockParser parser) {
    final current = parser.current.content;
    final match = pattern.firstMatch(current)!;
    final label = match[2]!;
    parser.advance();
    final lines = [
      current.substring(match[0]!.length),
      ...parseChildLines(parser).map((line) => line.content),
    ];
    if (collected.every((footnote) => footnote.label != label)) {
      collected.add(KnowledgeFootnote(
        label: label,
        number: collected.length + 1,
        markdown: lines.join('\n').trim(),
      ));
    }
    return null;
  }
}

/// Rendert `[^label]` als hochgestellte Nummer, die zur Fußnote springt.
/// Verweise ohne Definition bleiben als Text stehen.
class KnowledgeFootnoteReferenceSyntax extends md.InlineSyntax {
  KnowledgeFootnoteReferenceSyntax(this.footnotes)
      : super(r'\[\^([^\]\s]+)\]', startCharacter: '['.codeUnitAt(0));

  final KnowledgeFootnotes footnotes;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final footnote = footnotes.byLabel(match[1]!);
    if (footnote == null) {
      parser.addNode(md.Text(match[0]!));
      return true;
    }
    final link = md.Element.text('a', '${footnote.number}')
      ..attributes['href'] = knowledgeFootnoteHref(footnote.label);
    parser.addNode(md.Element('sup', [link]));
    return true;
  }
}
