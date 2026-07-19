import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/root_app_bar.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_side_panel.dart';

class TaskBuilderShellFrame extends StatefulWidget {
  const TaskBuilderShellFrame({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.child,
  });

  final Widget title;
  final VoidCallback onMenuPressed;
  final Widget child;

  @override
  State<TaskBuilderShellFrame> createState() => _TaskBuilderShellFrameState();
}

class _TaskBuilderShellFrameState extends State<TaskBuilderShellFrame> {
  TaskBuilderSidePanelKind? _sidePanel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
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
            _TaskBuilderShellDrawer(panel: _sidePanel, onClose: _closePanel),
            Positioned(
              top: 0,
              right: 0,
              child: TaskBuilderSideRail(
                selectedPanel: _sidePanel,
                onPanelSelected: _togglePanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePanel(TaskBuilderSidePanelKind panel) {
    setState(() => _sidePanel = _sidePanel == panel ? null : panel);
  }

  void _closePanel() {
    setState(() => _sidePanel = null);
  }
}

class _TaskBuilderShellDrawer extends StatelessWidget {
  const _TaskBuilderShellDrawer({required this.panel, required this.onClose});

  final TaskBuilderSidePanelKind? panel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      top: 0,
      right: panel == null ? -430 : 56,
      bottom: 0,
      child: IgnorePointer(
        ignoring: panel == null,
        child: panel == null
            ? const SizedBox(width: 390)
            : Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: TaskBuilderSideDrawer(panel: panel!, onClose: onClose),
              ),
      ),
    );
  }
}
