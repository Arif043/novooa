import 'package:flutter/widgets.dart';

import 'agent_cursor_controller.dart';

class AgentCursorScope extends InheritedWidget {
  const AgentCursorScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AgentCursorController controller;

  static AgentCursorController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<AgentCursorScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(AgentCursorScope oldWidget) =>
      controller != oldWidget.controller;
}
