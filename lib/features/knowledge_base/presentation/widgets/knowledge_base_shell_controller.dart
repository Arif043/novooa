import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/widgets/root_shell_scope.dart';

import '../cubits/knowledge_base_cubit.dart';

class KnowledgeBaseShellController extends StatefulWidget {
  const KnowledgeBaseShellController({super.key, required this.child});

  final Widget child;

  @override
  State<KnowledgeBaseShellController> createState() =>
      _KnowledgeBaseShellControllerState();
}

class _KnowledgeBaseShellControllerState
    extends State<KnowledgeBaseShellController> {
  RootShellController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = RootShellScope.of(context);
    if (_controller == controller) return;
    _controller = controller;
    _setControllerAfterFrame(controller, context.read<KnowledgeBaseCubit>());
  }

  @override
  void dispose() {
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.setKnowledgeBaseController(null);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _setControllerAfterFrame(
    RootShellController controller,
    KnowledgeBaseCubit cubit,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller != controller) return;
      controller.setKnowledgeBaseController(cubit);
    });
  }
}
