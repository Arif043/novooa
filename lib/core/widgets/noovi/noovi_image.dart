import 'package:flutter/material.dart';

import 'noovi_pose.dart';

/// Noovi in einer Pose. Ohne [semanticLabel] ist das Bild dekorativ und für
/// Screenreader unsichtbar, etwa neben einem Text, der schon alles sagt.
class NooviImage extends StatelessWidget {
  const NooviImage({
    super.key,
    required this.pose,
    required this.size,
    this.semanticLabel,
  });

  final NooviPose pose;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      pose.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
