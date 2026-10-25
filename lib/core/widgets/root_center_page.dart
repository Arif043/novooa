import 'package:flutter/material.dart';

import '../../features/knowledge_base/presentation/widgets/knowledge_base_shell_frame.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';
import '../../features/task_builder/presentation/widgets/task_builder_shell_frame.dart';
import 'root_app_bar.dart';

class RootCenterPage extends StatelessWidget {
  const RootCenterPage({
    super.key,
    required this.title,
    required this.usesTaskBuilderSideRail,
    required this.usesKnowledgeBaseSideRail,
    required this.content,
    required this.onMenuPressed,
    required this.menuWidthOfScreen,
    required this.onNotificationPressed,
  });

  final Widget title;
  final bool usesTaskBuilderSideRail;
  final bool usesKnowledgeBaseSideRail;
  final Widget content;
  final VoidCallback onMenuPressed;
  final double menuWidthOfScreen;
  final VoidCallback onNotificationPressed;

  @override
  Widget build(BuildContext context) {
    if (usesTaskBuilderSideRail) return _taskBuilderFrame();
    if (usesKnowledgeBaseSideRail) return _knowledgeBaseFrame();
    return _defaultFrame();
  }

  Widget _taskBuilderFrame() {
    return TaskBuilderShellFrame(
      title: title,
      onMenuPressed: onMenuPressed,
      menuWidthOfScreen: menuWidthOfScreen,
      child: content,
    );
  }

  Widget _knowledgeBaseFrame() {
    return KnowledgeBaseShellFrame(
      title: title,
      onMenuPressed: onMenuPressed,
      menuWidthOfScreen: menuWidthOfScreen,
      child: content,
    );
  }

  Widget _defaultFrame() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: RootAppBar(
        title: title,
        onMenuPressed: onMenuPressed,
        actions: [NotificationBellButton(onPressed: onNotificationPressed)],
      ),
      body: SafeArea(child: content),
    );
  }
}
