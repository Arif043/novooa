import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Hilfetext unter einem Eingabefeld, gestaltet wie der Hilfetext von
/// [InputDecoration].
class FieldHelperText extends StatelessWidget {
  const FieldHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
