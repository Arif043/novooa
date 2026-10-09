import 'package:flutter/widgets.dart';

import 'agent_cursor_controller.dart';
import 'agent_cursor_scope.dart';
import 'agent_cursor_target.dart';

/// Macht ein Widget für den Agent-Cursor auffindbar. Ohne Scope inaktiv.
class AgentCursorAnchor extends StatefulWidget {
  const AgentCursorAnchor({
    super.key,
    required this.target,
    required this.child,
    this.onActivate,
  });

  final AgentCursorTarget target;
  final Widget child;

  /// Wird ausgeführt, wenn der Agent auf dieses Ziel „klickt“.
  final VoidCallback? onActivate;

  @override
  State<AgentCursorAnchor> createState() => _AgentCursorAnchorState();
}

class _AgentCursorAnchorState extends State<AgentCursorAnchor> {
  final _globalKey = GlobalKey();
  AgentCursorController? _controller;
  AgentCursorTarget? _registered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregister();
    _controller = AgentCursorScope.maybeOf(context);
    _register();
  }

  @override
  void didUpdateWidget(AgentCursorAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _unregister();
    _register();
  }

  void _register() {
    _controller?.registry.register(
      widget.target,
      _globalKey,
      onActivate: widget.onActivate,
    );
    _registered = widget.target;
  }

  void _unregister() {
    final target = _registered;
    if (target != null) _controller?.registry.unregister(target, _globalKey);
    _registered = null;
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _globalKey, child: widget.child);
  }
}
