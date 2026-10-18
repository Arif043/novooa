import 'package:flutter/material.dart';

/// Punktraster als Hintergrund der Leinwand.
class CanvasDotsPainter extends CustomPainter {
  const CanvasDotsPainter(this.color, this.background);
  final Color color;
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = color.withValues(alpha: .4);
    for (double x = 12; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), .8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasDotsPainter oldDelegate) =>
      color != oldDelegate.color || background != oldDelegate.background;
}

/// Das Punktraster in den Farben des Themes, hinter der Leinwand.
class CanvasDotsBackground extends StatelessWidget {
  const CanvasDotsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        painter: CanvasDotsPainter(
          colors.outlineVariant,
          colors.surfaceContainerLowest,
        ),
      ),
    );
  }
}
