import 'package:flutter/widgets.dart';

import 'agent_cursor_target.dart';

class _AnchorEntry {
  const _AnchorEntry(this.key, this.onActivate);

  final GlobalKey key;
  final VoidCallback? onActivate;
}

class AgentCursorRegistry {
  final _entries = <AgentCursorTarget, _AnchorEntry>{};

  void register(
    AgentCursorTarget target,
    GlobalKey key, {
    VoidCallback? onActivate,
  }) => _entries[target] = _AnchorEntry(key, onActivate);

  void unregister(AgentCursorTarget target, GlobalKey key) {
    if (_entries[target]?.key == key) _entries.remove(target);
  }

  /// Löst die Aktion aus, die ein echter Tipp auf das Ziel auslösen würde.
  void activate(AgentCursorTarget target) =>
      _entries[target]?.onActivate?.call();

  BuildContext? contextOf(AgentCursorTarget target) =>
      _entries[target]?.key.currentContext;

  Rect? globalRectOf(AgentCursorTarget target) {
    final box = contextOf(target)?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
