import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/syscat_theme.dart';

class SyscatBackground extends StatelessWidget {
  const SyscatBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SyscatTheme.backgroundLight,
      child: Stack(
        children: [
          const _BackgroundBlob(
            top: -180,
            left: -120,
            size: 520,
            opacity: 0.45,
          ),
          const _BackgroundBlob(
            bottom: -220,
            right: -180,
            size: 620,
            opacity: 0.35,
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: const SizedBox(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  const _BackgroundBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SyscatTheme.primaryOrangeLight.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
