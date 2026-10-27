import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'database_cell_value.dart';

/// Eine Zelle mit Rasterlinien; der volle Text steht im Tooltip.
class DatabaseSheetCell extends StatelessWidget {
  const DatabaseSheetCell({
    super.key,
    required this.value,
    required this.width,
    this.muted = false,
  });

  final DatabaseCellValue value;
  final double width;

  /// Gedämpft für Hilfsspalten wie die Zeilennummer.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final number = value.kind == DatabaseValueKind.number;
    return DatabaseCellFrame(
      width: width,
      alignment: number ? Alignment.centerRight : Alignment.centerLeft,
      child: Tooltip(
        message: value.text,
        child: value.kind == DatabaseValueKind.boolean
            ? _BooleanLabel(value: value)
            : _ValueText(value: value, muted: muted),
      ),
    );
  }
}

/// Rahmen jeder Zelle: Innenabstand und Rasterlinien rechts und unten.
class DatabaseCellFrame extends StatelessWidget {
  const DatabaseCellFrame({
    super.key,
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      alignment: alignment,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: child,
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText({required this.value, required this.muted});

  final DatabaseCellValue value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet =
        muted ||
        value.kind == DatabaseValueKind.empty ||
        value.kind == DatabaseValueKind.structure;
    return Text(
      value.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: quiet ? theme.colorScheme.onSurfaceVariant : null,
        fontStyle: value.kind == DatabaseValueKind.structure
            ? FontStyle.italic
            : null,
        // Ziffern gleicher Breite: Zahlen untereinander bleiben vergleichbar.
        fontFeatures: value.kind == DatabaseValueKind.number
            ? const [FontFeature.tabularFigures()]
            : null,
      ),
    );
  }
}

class _BooleanLabel extends StatelessWidget {
  const _BooleanLabel({required this.value});

  final DatabaseCellValue value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: value.isTrue
            ? colors.primary.withValues(alpha: .12)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          value.text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: value.isTrue ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
