import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'workflow_canvas_frame.dart';
import 'workflow_canvas_options.dart';

/// Zeichnet die Kanten eines [CanvasFrame]; während eines Übergangs blenden
/// Kanten mit ihren Bausteinen ein und aus.
class WorkflowEdgesPainter extends CustomPainter {
  const WorkflowEdgesPainter(this.frame, this.colors);
  final CanvasFrame frame;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    for (final frameLink in frame.links) {
      final edge = frameLink.link;
      if (edge.isReturn && !WorkflowCanvasOptions.showReturnEdges) continue;
      final from = frameLink.from;
      final to = frameLink.to;
      final start = from.bottomCenter;
      final end = to.topCenter;
      final base = edge.labels.isEmpty
          ? colors.onSurfaceVariant.withValues(alpha: .6)
          : colors.secondary;
      final color = base.withValues(alpha: base.a * frameLink.opacity);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(start.dx, start.dy);
      final middle = (start.dy + end.dy) / 2;
      if (edge.isReturn && end.dy > start.dy) {
        // Collect returns just above the continuation, below every branch.
        final joinY = end.dy - 32;
        path.lineTo(start.dx, joinY);
        path.lineTo(end.dx, joinY);
        path.lineTo(end.dx, end.dy);
      } else if (end.dy > start.dy && (start.dx - end.dx).abs() < .01) {
        path.lineTo(end.dx, end.dy);
      } else if (end.dy > start.dy && end.dy - start.dy < 200) {
        path.cubicTo(start.dx, middle, end.dx, middle, end.dx, end.dy);
      } else {
        // Route long and backward edges outside the cards.
        final side = math.min(from.left, to.left) - 30;
        path.lineTo(start.dx, start.dy + 20);
        path.lineTo(side, start.dy + 20);
        path.lineTo(side, end.dy - 24);
        path.lineTo(end.dx, end.dy - 24);
        path.lineTo(end.dx, end.dy);
      }
      if (edge.isReturn) {
        for (final metric in path.computeMetrics()) {
          for (double offset = 0; offset < metric.length; offset += 12) {
            canvas.drawPath(
              metric.extractPath(offset, math.min(offset + 6, metric.length)),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
      canvas.drawPath(
        Path()
          ..moveTo(end.dx - 5, end.dy - 7)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx + 5, end.dy - 7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WorkflowEdgesPainter oldDelegate) => true;
}

/// Anker-Punkt für die Label-Chips eines Pfeils — exakt derselbe
/// Mittelpunkt, den der Pfeil selbst in [WorkflowEdgesPainter] anpeilt
/// (`start`/`end`/`middle`), damit Pfeil und Chip-Stapel optisch
/// zusammenpassen.
Offset canvasLabelAnchor(FrameLink link) {
  final start = link.from.bottomCenter;
  final end = link.to.topCenter;
  return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
}
