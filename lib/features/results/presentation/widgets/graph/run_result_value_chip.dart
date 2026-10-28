import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Ein Wert oder ein Zweig-Label auf einem Pfeil.
class RunResultValueChip extends StatelessWidget {
  const RunResultValueChip({
    super.key,
    required this.text,
    required this.isCondition,
  });

  static const _maximumLength = 40;

  final String text;
  final bool isCondition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shortened = text.length <= _maximumLength
        ? text
        : '${text.substring(0, _maximumLength - 1)}…';
    return Tooltip(
      message: text,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: isCondition
              ? colors.surfaceContainerHigh
              : colors.primaryContainer,
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            shortened,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isCondition ? colors.onSurface : colors.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
