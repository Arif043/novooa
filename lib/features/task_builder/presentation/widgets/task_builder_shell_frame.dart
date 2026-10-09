import 'package:flutter/material.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_controller.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_overlay.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_scope.dart';
import 'task_builder_header.dart';
import 'task_builder_theme.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_side_panel.dart';

class TaskBuilderShellFrame extends StatefulWidget {
  const TaskBuilderShellFrame({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.menuWidthOfScreen,
    required this.child,
  });

  final Widget title;
  final VoidCallback onMenuPressed;
  final double menuWidthOfScreen;
  final Widget child;

  @override
  State<TaskBuilderShellFrame> createState() => _TaskBuilderShellFrameState();
}

class _TaskBuilderShellFrameState extends State<TaskBuilderShellFrame> {
  final _controller = CupertinoSidemenuController();
  final _cursor = AgentCursorController();
  TaskBuilderSidePanelKind? _sidePanel;

  @override
  void dispose() {
    _controller.dispose();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: TaskBuilderTheme.from(Theme.of(context)),
      child: AgentCursorScope(
        controller: _cursor,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(child: _sidemenu()),
            ),
            Positioned.fill(child: AgentCursorOverlay(controller: _cursor)),
          ],
        ),
      ),
    );
  }

  Widget _sidemenu() {
    return CupertinoSidemenu(
      controller: _controller,
      hapticFeedback: false,
      centerBackgroundOpacity: 0.16,
      menuWidthOfScreen: widget.menuWidthOfScreen,
      rightMenu: _sidePanel == null ? null : _rightMenu(),
      centerPage: Column(
        children: [
          TaskBuilderHeader(
            title: widget.title,
            onMenuPressed: widget.onMenuPressed,
            actions: TaskBuilderSideRail(
              selectedPanel: _sidePanel,
              onPanelSelected: _openPanel,
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _rightMenu() {
    final panel = _sidePanel;
    if (panel == null) return const SizedBox.shrink();
    return TaskBuilderSideDrawer(panel: panel, onClose: _closePanel);
  }

  void _openPanel(TaskBuilderSidePanelKind panel) {
    setState(() => _sidePanel = panel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.openRightMenu();
    });
  }

  void _closePanel() {
    _controller.closeMenu();
    setState(() => _sidePanel = null);
  }
}
