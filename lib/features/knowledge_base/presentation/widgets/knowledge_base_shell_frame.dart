import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/widgets/root_app_bar.dart';
import 'package:syscat2/core/widgets/root_shell_scope.dart';

import '../cubits/knowledge_base_cubit.dart';
import 'knowledge_base_side_panel.dart';
import 'knowledge_base_theme.dart';

class KnowledgeBaseShellFrame extends StatefulWidget {
  const KnowledgeBaseShellFrame({
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
  State<KnowledgeBaseShellFrame> createState() =>
      _KnowledgeBaseShellFrameState();
}

class _KnowledgeBaseShellFrameState extends State<KnowledgeBaseShellFrame> {
  final _controller = CupertinoSidemenuController();
  KnowledgeBaseSidePanelKind? _sidePanel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KnowledgeBaseTheme.from(Theme.of(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _sideMenu()),
      ),
    );
  }

  Widget _sideMenu() {
    return CupertinoSidemenu(
      controller: _controller,
      hapticFeedback: false,
      centerBackgroundOpacity: 0.16,
      menuWidthOfScreen: widget.menuWidthOfScreen,
      rightMenu: _sidePanel == null ? null : _rightMenu(),
      centerPage: Column(
        children: [
          RootAppBar(
            title: widget.title,
            onMenuPressed: widget.onMenuPressed,
            actions: [
              KnowledgeBaseSideRail(
                selectedPanel: _sidePanel,
                onPanelSelected: _openPanel,
              ),
            ],
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _rightMenu() {
    final panel = _sidePanel;
    final cubit = RootShellScope.of(context).knowledgeBaseController;
    if (panel == null || cubit is! KnowledgeBaseCubit) {
      return const SizedBox.shrink();
    }
    return KnowledgeBaseSideDrawer(
      panel: panel,
      onClose: _closePanel,
      knowledgeBaseCubit: cubit,
    );
  }

  void _openPanel(KnowledgeBaseSidePanelKind panel) {
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
