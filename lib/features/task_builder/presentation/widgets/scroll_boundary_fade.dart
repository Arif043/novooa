import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class ScrollBoundaryFade extends StatefulWidget {
  const ScrollBoundaryFade({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<ScrollBoundaryFade> createState() => _ScrollBoundaryFadeState();
}

class _ScrollBoundaryFadeState extends State<ScrollBoundaryFade> {
  var _fadeTop = false;
  var _fadeBottom = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void didUpdateWidget(ScrollBoundaryFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_updateFades);
    widget.controller.addListener(_updateFades);
    _updateFades();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFades);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: _fadeShader,
      child: widget.child,
    );
  }

  Shader _fadeShader(Rect bounds) {
    final fadeFraction = (AppSpacing.xl / bounds.height)
        .clamp(0.0, 0.5)
        .toDouble();
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _fadeTop ? Colors.transparent : Colors.white,
        Colors.white,
        Colors.white,
        _fadeBottom ? Colors.transparent : Colors.white,
      ],
      stops: [0, fadeFraction, 1 - fadeFraction, 1],
    ).createShader(bounds);
  }

  void _updateFades() {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final fadeTop = position.extentBefore > 0;
    final fadeBottom = position.extentAfter > 0;
    if (_fadeTop == fadeTop && _fadeBottom == fadeBottom) return;
    setState(() {
      _fadeTop = fadeTop;
      _fadeBottom = fadeBottom;
    });
  }
}
