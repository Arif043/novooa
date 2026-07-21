import 'package:flutter/material.dart';

class NodePositionTransition extends StatefulWidget {
  const NodePositionTransition({
    super.key,
    required this.offsetY,
    required this.child,
    this.duration = const Duration(milliseconds: 650),
  });

  final double offsetY;
  final Widget child;
  final Duration duration;

  @override
  State<NodePositionTransition> createState() => _NodePositionTransitionState();
}

class _NodePositionTransitionState extends State<NodePositionTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _startOffsetY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..value = 1;
  }

  @override
  void didUpdateWidget(NodePositionTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.offsetY == 0) return;
    _startOffsetY = widget.offsetY;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeInOutCubic.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, _startOffsetY * (1 - progress)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
