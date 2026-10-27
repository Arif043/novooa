import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Eine Zelle mit Rasterlinien; zeigt den vollen Text im Tooltip.
class DatabaseSheetCell extends StatelessWidget {
  const DatabaseSheetCell({
    super.key,
    required this.text,
    required this.width,
    this.header = false,
    this.letter,
    this.trailing,
  });

  final String text;
  final double width;
  final bool header;

  /// Spaltenbuchstabe über dem Namen, wie in einer Tabellenkalkulation.
  final String? letter;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.centerLeft,
      decoration: databaseCellBorder(theme.colorScheme),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: text,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (letter != null)
                    Text(letter!, style: theme.textTheme.bodySmall),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: header
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

BoxDecoration databaseCellBorder(ColorScheme colors) => BoxDecoration(
  border: Border(
    right: BorderSide(color: colors.outlineVariant),
    bottom: BorderSide(color: colors.outlineVariant),
  ),
);

/// Spaltenbuchstaben A, B, … Z, AA, AB …
String databaseColumnLetter(int index) {
  var result = '';
  for (var value = index + 1; value > 0; value = (value - 1) ~/ 26) {
    result = String.fromCharCode(65 + (value - 1) % 26) + result;
  }
  return result;
}
