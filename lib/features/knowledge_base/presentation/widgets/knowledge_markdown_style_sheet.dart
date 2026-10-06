import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';

/// Markdown-Darstellung der Lesen-Ansicht, vollständig aus dem Theme abgeleitet.
abstract final class KnowledgeMarkdownStyleSheet {
  static MarkdownStyleSheet from(ThemeData theme) {
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final body = text.bodyLarge?.copyWith(height: 1.55);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: body,
      blockSpacing: AppSpacing.md,
      h1: text.headlineMedium,
      h1Padding: const EdgeInsets.only(top: AppSpacing.md),
      h2: text.headlineSmall,
      h2Padding: const EdgeInsets.only(top: AppSpacing.md),
      h3: text.titleLarge,
      h3Padding: const EdgeInsets.only(top: AppSpacing.sm),
      h4: text.titleMedium,
      h5: text.titleSmall,
      h6: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      a: body?.copyWith(
        color: colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: colors.primary,
      ),
      listIndent: AppSpacing.lg,
      listBullet: body?.copyWith(color: colors.onSurfaceVariant),
      checkbox: body?.copyWith(color: colors.primary),
      code: _code(text, colors),
      codeblockPadding: const EdgeInsets.all(AppSpacing.md),
      codeblockDecoration: _panel(colors),
      blockquote: body?.copyWith(color: colors.onSurfaceVariant),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      blockquoteDecoration: _quote(colors),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      tableHead: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      tableBody: text.bodyMedium,
      tableBorder: TableBorder.all(color: colors.outlineVariant),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      tableHeadCellsDecoration: BoxDecoration(color: colors.surfaceContainerLow),
    );
  }

  static TextStyle? _code(TextTheme text, ColorScheme colors) {
    return text.bodyMedium?.copyWith(
      fontFamily: SyscatTheme.codeFontFamilyFallback.first,
      fontFamilyFallback: SyscatTheme.codeFontFamilyFallback,
      backgroundColor: colors.surfaceContainerLow,
    );
  }

  static BoxDecoration _panel(ColorScheme colors) {
    return BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      border: Border.all(color: colors.outlineVariant),
    );
  }

  static BoxDecoration _quote(ColorScheme colors) {
    return BoxDecoration(
      color: colors.primary.withValues(alpha: 0.06),
      border: Border(left: BorderSide(color: colors.primary, width: AppSpacing.xs)),
    );
  }
}
