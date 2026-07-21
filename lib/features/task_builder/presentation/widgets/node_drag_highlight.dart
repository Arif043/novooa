import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class NodeDragHighlight extends StatelessWidget {
  const NodeDragHighlight({
    super.key,
    required this.active,
    required this.child,
  });

  static const animationDuration = Duration(milliseconds: 220);
  static const _activeScale = 1.015;
  static const _borderWidth = 2.0;
  static const _borderOpacity = 0.55;
  static const _shadowOpacity = 0.24;

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? _activeScale : 1,
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        decoration: _decoration(context),
        child: child,
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      border: Border.all(
        color: primary.withValues(alpha: active ? _borderOpacity : 0),
        width: _borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: active ? _shadowOpacity : 0),
          blurRadius: active ? AppSpacing.lg : 0,
          spreadRadius: active ? AppSpacing.xs : 0,
        ),
      ],
    );
  }
}
