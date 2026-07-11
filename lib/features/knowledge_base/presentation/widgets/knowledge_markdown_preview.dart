import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class KnowledgeMarkdownPreview extends StatelessWidget {
  const KnowledgeMarkdownPreview({super.key, required this.content});

  final String content;

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
        itemBuilder: (context, index) {
          return _PreviewLine(line: lines[index]);
        },
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final text = line.trimRight();
    if (text.isEmpty) return const SizedBox(height: AppSpacing.sm);
    if (text.startsWith('# ')) {
      return _LineText(
        text.substring(2),
        Theme.of(context).textTheme.headlineSmall,
      );
    }
    if (text.startsWith('## ')) {
      return _LineText(
        text.substring(3),
        Theme.of(context).textTheme.titleLarge,
      );
    }
    if (text.startsWith('- ')) {
      return _LineText(
        '• ${text.substring(2)}',
        Theme.of(context).textTheme.bodyMedium,
      );
    }
    return _LineText(
      _formatWikiLinks(text),
      Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _LineText extends StatelessWidget {
  const _LineText(this.text, this.style);

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: style),
    );
  }
}

String _formatWikiLinks(String text) {
  return text.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (match) {
    return '↗ ${match.group(1) ?? ''}';
  });
}
