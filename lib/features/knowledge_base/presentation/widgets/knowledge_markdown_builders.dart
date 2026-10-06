import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import 'knowledge_markdown_syntaxes.dart';

Map<String, MarkdownElementBuilder> knowledgeMarkdownBuilders(ThemeData theme) {
  return {
    knowledgeMathTag: KnowledgeMathBuilder(theme),
    knowledgeHighlightTag: KnowledgeHighlightBuilder(theme),
  };
}

/// Rendert Formeln mit `flutter_math_fork`. Inline-Formeln stehen als
/// `WidgetSpan` im Textfluss, Formel-Blöcke sind horizontal scrollbar.
class KnowledgeMathBuilder extends MarkdownElementBuilder {
  KnowledgeMathBuilder(this.theme);

  final ThemeData theme;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    if (tex.isEmpty) return const SizedBox.shrink();
    final display = element.attributes[knowledgeMathStyleAttribute] == 'display';
    final formula = _formula(tex, display, parentStyle ?? preferredStyle);
    if (!display) {
      return Text.rich(WidgetSpan(alignment: PlaceholderAlignment.middle, child: formula));
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: formula);
  }

  Widget _formula(String tex, bool display, TextStyle? style) {
    return Semantics(
      label: 'Formel: $tex',
      child: Math.tex(
        tex,
        mathStyle: display ? MathStyle.display : MathStyle.text,
        textStyle: style,
        onErrorFallback: (error) => Text(
          tex,
          style: style?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}

/// Hinterlegt `==markierten==` Text mit dem Akzent des Themes.
class KnowledgeHighlightBuilder extends MarkdownElementBuilder {
  KnowledgeHighlightBuilder(this.theme);

  final ThemeData theme;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final base = parentStyle ?? preferredStyle ?? theme.textTheme.bodyLarge;
    return Text.rich(TextSpan(
      text: element.textContent,
      style: base?.copyWith(
        backgroundColor: Colors.amber.withValues(alpha: 0.9),
      ),
    ));
  }
}
