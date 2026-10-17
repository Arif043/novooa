import 'package:flutter/material.dart';

import '../../domain/entities/scan_quad.dart';

/// Zeichnet die erkannte Dokumentkontur über das Kamerabild.
///
/// Die Kontur gleitet zwischen zwei Erkennungen zur neuen Lage und blendet
/// weich ein und aus, statt zu springen.
class ScanQuadOverlay extends StatefulWidget {
  const ScanQuadOverlay({super.key, required this.quad});

  /// Etwa so lang wie der Abstand zweier Erkennungen, damit die Bewegung
  /// fließend bleibt.
  static const Duration glideDuration = Duration(milliseconds: 150);
  static const Duration fadeDuration = Duration(milliseconds: 200);

  final ScanQuad? quad;

  @override
  State<ScanQuadOverlay> createState() => _ScanQuadOverlayState();
}

class _ScanQuadOverlayState extends State<ScanQuadOverlay> {
  /// Bleibt beim Ausblenden stehen, damit die Kontur an ihrem Platz verblasst.
  ScanQuad? _lastQuad;

  /// Wechselt bei jedem Erscheinen: Eine neue Kontur taucht an ihrem Platz
  /// auf, statt von der alten Stelle herüberzugleiten.
  int _appearance = 0;

  @override
  void initState() {
    super.initState();
    _lastQuad = widget.quad;
  }

  @override
  void didUpdateWidget(ScanQuadOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final quad = widget.quad;
    if (quad == null) return;
    if (oldWidget.quad == null) _appearance++;
    _lastQuad = quad;
  }

  @override
  Widget build(BuildContext context) {
    final target = _lastQuad;
    if (target == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: AnimatedOpacity(
        opacity: widget.quad == null ? 0 : 1,
        duration: ScanQuadOverlay.fadeDuration,
        child: TweenAnimationBuilder<ScanQuad>(
          key: ValueKey(_appearance),
          tween: _ScanQuadTween(end: target),
          duration: ScanQuadOverlay.glideDuration,
          curve: Curves.easeOut,
          builder: (context, quad, _) => CustomPaint(
            painter: _QuadPainter(quad: quad, color: color),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _ScanQuadTween extends Tween<ScanQuad> {
  _ScanQuadTween({required ScanQuad super.end});

  @override
  ScanQuad lerp(double t) => begin!.lerp(end!, t);
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
