import 'package:flutter/material.dart';

/// Hintergrund des Wissensgraphen: ein ruhiger radialer Verlauf aus den
/// Flächenfarben mit einem zarten Akzent-Schimmer in der Mitte und einer
/// leichten Vignette zu den Rändern. Alle Farben kommen aus dem Theme.
class KnowledgeGraphBackground extends StatelessWidget {
  const KnowledgeGraphBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: [
            Color.alphaBlend(
              colors.primary.withValues(alpha: dark ? .12 : .07),
              colors.surface,
            ),
            colors.surface,
            colors.surfaceContainerLow,
          ],
          stops: const [0, .55, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.25,
            colors: [
              colors.shadow.withValues(alpha: 0),
              colors.shadow.withValues(alpha: dark ? .32 : .07),
            ],
            stops: const [.6, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}
