import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Karten in 1–4 Spalten je nach Breite (wie die Aufgabenübersicht).
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({super.key, required this.children});

  /// Jedes Kind sollte einen eigenen `Key` tragen.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCountFor(constraints.maxWidth);
        final tileWidth = _tileWidthFor(constraints.maxWidth, columnCount);
        return SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final child in children)
                  SizedBox(key: child.key, width: tileWidth, child: child),
              ],
            ),
          ),
        );
      },
    );
  }

  int _columnCountFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  double _tileWidthFor(double width, int columnCount) {
    final spacing = AppSpacing.md * (columnCount - 1);
    return (width - spacing) / columnCount;
  }
}
