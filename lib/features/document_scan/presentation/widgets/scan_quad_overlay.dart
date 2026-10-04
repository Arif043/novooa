import 'package:flutter/material.dart';

import '../../domain/entities/scan_quad.dart';

/// Zeichnet die erkannte Dokumentkontur über das Kamerabild.
class ScanQuadOverlay extends StatelessWidget {
  const ScanQuadOverlay({super.key, required this.quad});

  final ScanQuad? quad;

  @override
  Widget build(BuildContext context) {
    final detected = quad;
    if (detected == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _QuadPainter(quad: detected, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  const _QuadPainter({required this.quad, required this.color});

  static const double _strokeWidth = 3;
  static const double _fillOpacity = 0.15;

  final ScanQuad quad;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final corner in quad.corners)
        Offset(corner.x * size.width, corner.y * size.height),
    ];
    final outline = Path()..addPolygon(points, true);
    canvas.drawPath(
      outline,
      Paint()..color = color.withValues(alpha: _fillOpacity),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter oldDelegate) {
    return oldDelegate.quad != quad || oldDelegate.color != color;
  }
}
