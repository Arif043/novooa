import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/agent_colors.dart';
import 'package:syscat2/core/widgets/noovi/noovi_avatar.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';

/// Ein Mitarbeiter als Noovi im Ring seiner festen Farbe.
class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.employeeId,
    this.size = 32,
    this.pose = NooviPose.present,
  });

  final String employeeId;
  final double size;
  final NooviPose pose;

  @override
  Widget build(BuildContext context) {
    return NooviAvatar(
      pose: pose,
      size: size,
      ringColor: AgentColors.memberColor(employeeId),
    );
  }
}
