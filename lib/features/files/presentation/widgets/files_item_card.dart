import 'package:flutter/material.dart';

/// Rahmen eines Eintrags — dieselbe Karte wie ein Auslöser im Zeitplan.
class FilesItemCard extends StatelessWidget {
  const FilesItemCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}
