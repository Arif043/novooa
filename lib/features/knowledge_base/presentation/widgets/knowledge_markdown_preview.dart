import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../../domain/services/wiki_link_parser.dart';

class KnowledgeMarkdownPreview extends StatelessWidget {
  const KnowledgeMarkdownPreview({
    super.key,
    required this.content,
    required this.notes,
    required this.onNoteSelected,
  });

  final String content;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: lines.length,
        itemBuilder: (context, index) => _PreviewLine(
          line: lines[index],
          notes: notes,
          onNoteSelected: onNoteSelected,
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.line,
    required this.notes,
    required this.onNoteSelected,
  });

  final String line;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;

  @override
  Widget build(BuildContext context) {
    final text = line.trimRight();
    if (text.isEmpty) return const SizedBox(height: AppSpacing.sm);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: _WikiLinkText(
        text: _displayText(text),
        style: _styleFor(context, text),
        notes: notes,
        onNoteSelected: onNoteSelected,
      ),
    );
  }

  TextStyle? _styleFor(BuildContext context, String text) {
    if (text.startsWith('# ')) return Theme.of(context).textTheme.headlineSmall;
    if (text.startsWith('## ')) return Theme.of(context).textTheme.titleLarge;
    return Theme.of(context).textTheme.bodyMedium;
  }

  String _displayText(String text) {
    if (text.startsWith('# ')) return text.substring(2);
    if (text.startsWith('## ')) return text.substring(3);
    if (text.startsWith('- ')) return '• ${text.substring(2)}';
    return text;
  }
}

class _WikiLinkText extends StatefulWidget {
  const _WikiLinkText({
    required this.text,
    required this.style,
    required this.notes,
    required this.onNoteSelected,
  });

  final String text;
  final TextStyle? style;
  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;

  @override
  State<_WikiLinkText> createState() => _WikiLinkTextState();
}

class _WikiLinkTextState extends State<_WikiLinkText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    return Text.rich(TextSpan(children: _spans(context)));
  }

  List<InlineSpan> _spans(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _wikiLinkPattern.allMatches(widget.text)) {
      spans.add(
        TextSpan(
          text: widget.text.substring(cursor, match.start),
          style: widget.style,
        ),
      );
      spans.add(_linkSpan(context, match));
      cursor = match.end;
    }
    spans.add(
      TextSpan(text: widget.text.substring(cursor), style: widget.style),
    );
    return spans;
  }

  InlineSpan _linkSpan(BuildContext context, RegExpMatch match) {
    final link = _wikiLinkParser(match.group(0)!).single;
    final note = _noteFor(link.target);
    if (note == null) {
      return TextSpan(text: match.group(0), style: widget.style);
    }
    return TextSpan(
      text: link.label,
      style: widget.style?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      semanticsLabel: 'Notiz ${note.title} öffnen',
      recognizer: _recognizerFor(note.id),
    );
  }

  KnowledgeNote? _noteFor(String target) {
    final normalizedTarget = target.trim().toLowerCase();
    for (final note in widget.notes) {
      final aliases = [
        note.id,
        note.title,
        note.path,
        _withoutMarkdownExtension(note.path),
      ];
      if (aliases.any(
        (alias) => alias.trim().toLowerCase() == normalizedTarget,
      )) {
        return note;
      }
    }
    return null;
  }

  String _withoutMarkdownExtension(String path) {
    return path.endsWith('.md') ? path.substring(0, path.length - 3) : path;
  }

  TapGestureRecognizer _recognizerFor(String noteId) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onNoteSelected(noteId);
    _recognizers.add(recognizer);
    return recognizer;
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}

final _wikiLinkPattern = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
const _wikiLinkParser = WikiLinkParser();
