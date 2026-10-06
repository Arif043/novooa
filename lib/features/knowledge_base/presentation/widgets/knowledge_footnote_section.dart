import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'knowledge_footnotes.dart';

/// Fußnoten unter dem Notiztext. Jede Fußnote hat eine Sprungmarke und einen
/// Rücksprung zur Textstelle.
class KnowledgeFootnoteSection extends StatelessWidget {
  const KnowledgeFootnoteSection({
    super.key,
    required this.footnotes,
    required this.keyFor,
    required this.contentFor,
    required this.onBack,
  });

  final KnowledgeFootnotes footnotes;
  final GlobalKey Function(String label) keyFor;
  final Widget Function(KnowledgeFootnote footnote) contentFor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Fußnoten',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: AppSpacing.xl),
          for (final footnote in footnotes.all)
            _FootnoteEntry(
              key: keyFor(footnote.label),
              footnote: footnote,
              content: contentFor(footnote),
              onBack: onBack,
            ),
        ],
      ),
    );
  }
}

class _FootnoteEntry extends StatelessWidget {
  const _FootnoteEntry({
    super.key,
    required this.footnote,
    required this.content,
    required this.onBack,
  });

  final KnowledgeFootnote footnote;
  final Widget content;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.sm),
          child: Text('${footnote.number}.', style: text.bodyMedium),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: content,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_return),
          tooltip: 'Zurück zur Textstelle',
          onPressed: onBack,
        ),
      ],
    );
  }
}
