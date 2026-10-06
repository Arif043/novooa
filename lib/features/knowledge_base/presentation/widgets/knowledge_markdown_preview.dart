import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_footnote_section.dart';
import 'knowledge_footnotes.dart';
import 'knowledge_markdown_builders.dart';
import 'knowledge_markdown_link_handler.dart';
import 'knowledge_markdown_style_sheet.dart';
import 'knowledge_markdown_syntaxes.dart';

/// Lesen-Ansicht einer Notiz: rendert GitHub-Flavored-Markdown samt
/// `[[Wiki-Links]]`, Fußnoten, Formeln, `==Markierungen==` und Emoji-Kürzeln.
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
          : _MarkdownDocument(
              content: content,
              notes: notes,
              onNoteSelected: onNoteSelected,
              openExternal: openExternal,
            ),
    );
  }
}

class _MarkdownDocument extends StatefulWidget {
  const _MarkdownDocument({
    required this.content,
    required this.notes,
    required this.onNoteSelected,
    required this.openExternal,
  });

  final String content;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;
  final ExternalLinkOpener openExternal;

  @override
  State<_MarkdownDocument> createState() => _MarkdownDocumentState();
}

class _MarkdownDocumentState extends State<_MarkdownDocument> {
  final _scroll = ScrollController();
  final _footnoteKeys = <String, GlobalKey>{};
  late KnowledgeFootnotes _footnotes;

  /// Wo gelesen wurde, bevor zu einer Fußnote gesprungen wurde.
  double? _returnOffset;

  @override
  void initState() {
    super.initState();
    _footnotes = _extractFootnotes();
  }

  @override
  void didUpdateWidget(_MarkdownDocument oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) _footnotes = _extractFootnotes();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KnowledgeFootnotes _extractFootnotes() {
    return KnowledgeFootnotes.extract(widget.content, knowledgeBlockSyntaxes());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _markdown(widget.content),
          if (!_footnotes.isEmpty)
            KnowledgeFootnoteSection(
              footnotes: _footnotes,
              keyFor: (label) => _footnoteKeys.putIfAbsent(label, GlobalKey.new),
              contentFor: (footnote) => _markdown(footnote.markdown),
              onBack: _jumpBack,
            ),
        ],
      ),
    );
  }

  Widget _markdown(String data) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: KnowledgeMarkdownStyleSheet.from(theme),
      extensionSet: knowledgeExtensionSet(notes: widget.notes, footnotes: _footnotes),
      builders: knowledgeMarkdownBuilders(theme),
      onTapLink: KnowledgeMarkdownLinkHandler(
        notes: widget.notes,
        onNoteSelected: widget.onNoteSelected,
        openExternal: widget.openExternal,
        onFootnoteSelected: _jumpToFootnote,
      ).call,
    );
  }

  void _jumpToFootnote(String label) {
    final target = _footnoteKeys[label]?.currentContext;
    if (target == null) return;
    _returnOffset = _scroll.offset;
    Scrollable.ensureVisible(target, duration: _scrollDuration, alignment: 0.1);
  }

  void _jumpBack() {
    final offset = (_returnOffset ?? 0).clamp(0.0, _scroll.position.maxScrollExtent);
    if (_scrollDuration == Duration.zero) {
      _scroll.jumpTo(offset);
      return;
    }
    _scroll.animateTo(offset, duration: _scrollDuration, curve: Curves.easeOutCubic);
  }

  Duration get _scrollDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 280);
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
