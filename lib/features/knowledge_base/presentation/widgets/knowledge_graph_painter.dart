import 'package:flutter/material.dart';

/// Zeichnet die Links des Wissensgraphen. Die Links, über die ein Prompt
/// von der gewählten Notiz aus weitere Notizen erreicht ([highlightedLinks],
/// gerichtet), leuchten in der Akzentfarbe; alle übrigen treten zurück.
class KnowledgeGraphPainter extends CustomPainter {
  const KnowledgeGraphPainter({
    required this.links,
    required this.positions,
    required this.colorScheme,
    required this.selectedNoteId,
    this.highlightedLinks = const {},
  });

  final Iterable<(String, String)> links;
  final Map<String, Offset> positions;
  final ColorScheme colorScheme;
  final String? selectedNoteId;
  final Set<(String, String)> highlightedLinks;

  /// Knotenmitte liegt über dem Label; die Linien treffen den Punkt.
  static const _dotOffset = Offset(0, -10);

  @override
  void paint(Canvas canvas, Size size) {
    final highlighted = <(Offset, Offset)>[];
    for (final (source, target) in links) {
      final from = positions[source];
      final to = positions[target];
      if (from == null || to == null) continue;
      if (highlightedLinks.contains((source, target)) ||
          highlightedLinks.contains((target, source))) {
        highlighted.add((from + _dotOffset, to + _dotOffset));
        continue;
      }
      canvas.drawLine(from + _dotOffset, to + _dotOffset, _restingPaint);
    }
    for (final (from, to) in highlighted) {
      canvas.drawLine(from, to, _glowPaint);
      canvas.drawLine(from, to, _highlightPaint);
    }
  }

  Paint get _restingPaint => Paint()
    ..color = colorScheme.onSurfaceVariant.withValues(
      alpha: selectedNoteId == null ? .22 : .1,
    )
    ..strokeWidth = 1.1
    ..style = PaintingStyle.stroke;

  Paint get _glowPaint => Paint()
    ..color = colorScheme.primary.withValues(alpha: .22)
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
    ..style = PaintingStyle.stroke;

  Paint get _highlightPaint => Paint()
    ..color = colorScheme.primary.withValues(alpha: .8)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  @override
  bool shouldRepaint(KnowledgeGraphPainter oldDelegate) => true;
}
