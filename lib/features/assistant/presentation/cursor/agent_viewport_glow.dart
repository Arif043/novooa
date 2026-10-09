import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Leuchtender Rand um den Viewport, solange der Agent die Oberfläche bedient.
///
/// Der Schein wächst beim Einblenden von den Rändern nach innen, atmet leicht
/// und trägt einen langsam umlaufenden Farbverlauf. Beim Ausblenden zieht er
/// sich wieder an den Rand zurück.
class AgentViewportGlow extends StatefulWidget {
  const AgentViewportGlow({super.key, required this.isActive});

  final bool isActive;

  @override
  State<AgentViewportGlow> createState() => _AgentViewportGlowState();
}

class _AgentViewportGlowState extends State<AgentViewportGlow>
    with TickerProviderStateMixin {
  late final _presence = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    reverseDuration: const Duration(milliseconds: 450),
  );
  late final _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _presence.addStatusListener(_stopFlowWhenHidden);
    if (widget.isActive) _show();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(AgentViewportGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    widget.isActive ? _show() : _hide();
  }

  void _show() {
    if (!_reduceMotion && !_flow.isAnimating) _flow.repeat();
    _reduceMotion ? _presence.value = 1 : _presence.forward();
  }

  void _hide() => _reduceMotion ? _presence.value = 0 : _presence.reverse();

  void _stopFlowWhenHidden(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _flow.stop();
  }

  @override
  void dispose() {
    _presence.dispose();
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primaryContainer;
    return AnimatedBuilder(
      animation: _presence,
      builder: (context, _) {
        if (_presence.isDismissed) return const SizedBox.shrink();
        return RepaintBoundary(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _GlowPainter(
                base: base,
                presence: _presence,
                flow: _flow,
                reduceMotion: _reduceMotion,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlowLayer {
  const _GlowLayer(this.width, this.blur, this.alpha);

  final double width;
  final double blur;
  final double alpha;
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.base,
    required this.presence,
    required this.flow,
    required this.reduceMotion,
  }) : super(repaint: Listenable.merge([presence, flow]));

  final Color base;
  final Animation<double> presence;
  final Animation<double> flow;
  final bool reduceMotion;

  // Von außen weich auslaufend nach innen scharf: ergibt einen gestaffelten
  // Schein statt eines einzelnen Blurs.
  static const _layers = [
    _GlowLayer(64, 36, 0.16),
    _GlowLayer(36, 20, 0.26),
    _GlowLayer(16, 9, 0.42),
    _GlowLayer(5, 3, 0.7),
    _GlowLayer(1.5, 0, 0.95),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final intensity = Curves.easeOutCubic.transform(presence.value);
    final breathing = reduceMotion ? 1.0 : _breathing();
    canvas.clipRect(bounds);
    for (final layer in _layers) {
      canvas.drawRect(bounds, _paintFor(layer, bounds, intensity * breathing));
    }
  }

  double _breathing() => 0.88 + 0.12 * math.sin(flow.value * 2 * math.pi * 2);

  Paint _paintFor(_GlowLayer layer, Rect bounds, double intensity) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = layer.width * intensity
      ..shader = _gradient(layer.alpha * intensity).createShader(bounds);
    if (layer.blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, layer.blur);
    }
    return paint;
  }

  SweepGradient _gradient(double alpha) {
    final hsl = HSLColor.fromColor(base);
    final warm = hsl.withHue((hsl.hue - 14) % 360).toColor();
    final light = Color.lerp(base, Colors.white, 0.5)!;
    return SweepGradient(
      transform: GradientRotation(flow.value * 2 * math.pi),
      colors: [
        for (final color in [base, light, warm, base, light, warm, base])
          color.withValues(alpha: alpha.clamp(0, 1)),
      ],
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.reduceMotion != reduceMotion;
}
