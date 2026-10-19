import 'package:flutter/material.dart';

import 'noovi_image.dart';
import 'noovi_pose.dart';

/// Noovi in einem farbigen Kreis: Die Ringfarbe zeigt, welcher Agent es ist
/// (siehe `AgentColors`). Ohne [semanticLabel] dekorativ.
class NooviAvatar extends StatelessWidget {
  const NooviAvatar({
    super.key,
    required this.pose,
    required this.size,
    required this.ringColor,
    this.semanticLabel,
  });

  final NooviPose pose;
  final double size;
  final Color ringColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: .12),
        border: Border.all(color: ringColor, width: 2),
      ),
      child: NooviImage(
        pose: pose,
        size: size * .8,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
