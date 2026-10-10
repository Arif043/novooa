import 'package:flutter/material.dart';

/// Baustein-Menü für schmale Bildschirme: gleitet von links herein, der
/// Hintergrund wird abgedunkelt.
///
/// Das Menü bleibt nur gebaut, solange es sichtbar ist oder gerade ausfährt.
/// So melden sich seine Cursor-Anker nicht an, wenn es zu ist.
class SlidingPaletteOverlay extends StatefulWidget {
  const SlidingPaletteOverlay({
    super.key,
    required this.visible,
    required this.width,
    required this.onDismiss,
    required this.child,
  });

  final bool visible;
  final double width;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<SlidingPaletteOverlay> createState() => _SlidingPaletteOverlayState();
}

class _SlidingPaletteOverlayState extends State<SlidingPaletteOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final _slide = Tween(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(_curve);

  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = widget.visible;
    _controller.addStatusListener(_unmountWhenClosed);
    if (widget.visible) _controller.value = 1;
  }

  @override
  void didUpdateWidget(SlidingPaletteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      setState(() => _mounted = true);
      _animate(forward: true);
    } else {
      _animate(forward: false);
    }
  }

  void _animate({required bool forward}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.value = forward ? 1 : 0;
    } else {
      forward ? _controller.forward() : _controller.reverse();
    }
  }

  void _unmountWhenClosed(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted && !widget.visible) {
      setState(() => _mounted = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Immer positioniert: Ein nicht positioniertes Kind würde den umgebenden
    // Stack auf seine eigene (leere) Größe zusammenziehen.
    return Positioned.fill(child: _mounted ? _menu() : const SizedBox.shrink());
  }

  Widget _menu() {
    return Stack(
      children: [
        FadeTransition(
          opacity: _curve,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(
              child: ColoredBox(color: Colors.black26),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: widget.width,
          child: SlideTransition(position: _slide, child: widget.child),
        ),
      ],
    );
  }
}
