import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

/// Ausgabe eines Scripts in Festbreitenschrift auf eigener Fläche. Die Fehlerausgabe (stderr,
/// [isError]) ist rötlich: Fehlerfarbe auf rötlicher Fläche.
class ConsoleOutputBlock extends StatelessWidget {
  const ConsoleOutputBlock({
    super.key,
    required this.text,
    this.isError = false,
  });

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: isError ? colors.error : colors.onSurface,
      fontFamilyFallback: SyscatTheme.codeFontFamilyFallback,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError
            ? colors.errorContainer.withValues(alpha: .35)
            : colors.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: SelectableText(text, style: style),
        ),
      ),
    );
  }
}
