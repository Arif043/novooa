import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_markdown_builders.dart';
import 'knowledge_markdown_link_handler.dart';
import 'knowledge_markdown_syntaxes.dart';

/// Antwort des Wissensbasis-Agenten: `[[Titel]]` wird zum Link, der die Notiz
/// öffnet; Links auf unbekannte Titel bleiben Text.
class KnowledgeAssistantMessageBody extends StatelessWidget {
  const KnowledgeAssistantMessageBody({
    super.key,
    required this.text,
    required this.notes,
    required this.onNoteSelected,
  });

  final String text;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: _styleSheetFor(theme),
      extensionSet: knowledgeExtensionSet(notes: notes),
      builders: knowledgeMarkdownBuilders(theme),
      onTapLink: KnowledgeMarkdownLinkHandler(
        notes: notes,
        onNoteSelected: onNoteSelected,
      ).call,
    );
  }

  MarkdownStyleSheet _styleSheetFor(ThemeData theme) {
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium,
      a: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
