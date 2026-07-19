import 'package:flutter/material.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:syscat2/core/widgets/root_app_bar.dart';
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
  TaskBuilderSidePanelKind? _sidePanel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: _sidemenu()),
    );
  }

  Widget _sidemenu() {
    return CupertinoSidemenu(
      controller: _controller,
      hapticFeedback: false,
      centerBackgroundOpacity: 0.16,
      menuWidthOfScreen: widget.menuWidthOfScreen,
      rightMenu: _sidePanel == null ? null : _rightMenu(),
      centerPage: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                RootAppBar(
                  title: widget.title,
                  onMenuPressed: widget.onMenuPressed,
                  actions: const [],
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: TaskBuilderSideRail(
              selectedPanel: _sidePanel,
              onPanelSelected: _openPanel,
            ),
          ),
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
