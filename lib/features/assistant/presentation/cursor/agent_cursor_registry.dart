import 'package:flutter/widgets.dart';

import 'agent_cursor_target.dart';

class AgentCursorRegistry {
  final _keys = <AgentCursorTarget, GlobalKey>{};

  void register(AgentCursorTarget target, GlobalKey key) => _keys[target] = key;

  void unregister(AgentCursorTarget target, GlobalKey key) {
    if (_keys[target] == key) _keys.remove(target);
  }

  BuildContext? contextOf(AgentCursorTarget target) =>
      _keys[target]?.currentContext;

  Rect? globalRectOf(AgentCursorTarget target) {
    final box = contextOf(target)?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
