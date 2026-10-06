import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_markdown_link_handler.dart';
import 'knowledge_markdown_style_sheet.dart';
import 'knowledge_wiki_link_syntax.dart';

/// Lesen-Ansicht einer Notiz: rendert GitHub-Flavored-Markdown samt
/// `[[Wiki-Links]]` und Emoji-Kürzeln.
class KnowledgeMarkdownPreview extends StatelessWidget {
  const KnowledgeMarkdownPreview({
    super.key,
    required this.content,
    required this.notes,
    required this.onNoteSelected,
    this.openExternal = launchExternalLink,
  });

  final String content;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;

  /// Öffnet Web- und Mail-Adressen; ohne Angabe der Systembrowser.
  final ExternalLinkOpener openExternal;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: content.trim().isEmpty
          ? const _EmptyNoteHint()
          : _MarkdownContent(
              content: content,
              notes: notes,
              linkHandler: KnowledgeMarkdownLinkHandler(
                notes: notes,
                onNoteSelected: onNoteSelected,
                openExternal: openExternal,
              ),
            ),
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({
    required this.content,
    required this.notes,
    required this.linkHandler,
  });

  final String content;
  final List<KnowledgeNote> notes;
  final KnowledgeMarkdownLinkHandler linkHandler;

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: content,
      selectable: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      styleSheet: KnowledgeMarkdownStyleSheet.from(Theme.of(context)),
      extensionSet: _extensionSet(),
      onTapLink: linkHandler.call,
    );
  }

  md.ExtensionSet _extensionSet() {
    final gitHub = md.ExtensionSet.gitHubFlavored;
    return md.ExtensionSet(gitHub.blockSyntaxes, [
      KnowledgeWikiLinkSyntax(notes: notes),
      md.EmojiSyntax(),
      ...gitHub.inlineSyntaxes,
    ]);
  }
}

class _EmptyNoteHint extends StatelessWidget {
  const _EmptyNoteHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Diese Notiz ist noch leer. Wechsle zu „Schreiben“, um Inhalt hinzuzufügen.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ColorScheme.of(context).onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
