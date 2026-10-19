import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';

/// Der fliegende Noovi als Cursor. Ein weicher Schatten hebt den hellen
/// Noovi von hellen Flächen ab, über die er fährt.
class AgentCursorNoovi extends StatelessWidget {
  const AgentCursorNoovi({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final shadow = Theme.of(context).colorScheme.shadow.withValues(alpha: .35);
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(1, 2),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(shadow, BlendMode.srcIn),
              child: NooviImage(pose: NooviPose.fly, size: size),
            ),
          ),
        ),
        NooviImage(pose: NooviPose.fly, size: size),
      ],
    );
  }
}
