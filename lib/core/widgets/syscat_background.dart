import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/syscat_theme.dart';

class SyscatBackground extends StatelessWidget {
  const SyscatBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _BackgroundPalette.forTheme(context);
    return ColoredBox(
      color: palette.base,
      child: Stack(
        children: [
          _BackgroundBlob(
            top: -180,
            left: -120,
            size: 520,
            color: palette.firstBlob,
          ),
          _BackgroundBlob(
            bottom: -220,
            right: -180,
            size: 620,
            color: palette.secondBlob,
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

class _BackgroundPalette {
  const _BackgroundPalette({
    required this.base,
    required this.firstBlob,
    required this.secondBlob,
  });

  factory _BackgroundPalette.forTheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return _BackgroundPalette(
        base: SyscatTheme.backgroundDark,
        firstBlob: Colors.white.withValues(alpha: 0.22),
        secondBlob: Colors.black.withValues(alpha: 0.62),
      );
    }
    return _BackgroundPalette(
      base: SyscatTheme.backgroundLight,
      firstBlob: SyscatTheme.primaryOrangeLight.withValues(alpha: 0.45),
      secondBlob: SyscatTheme.primaryOrangeLight.withValues(alpha: 0.35),
    );
  }

  final Color base;
  final Color firstBlob;
  final Color secondBlob;
}

class _BackgroundBlob extends StatelessWidget {
  const _BackgroundBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
