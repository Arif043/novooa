import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'agent_cursor_performer.dart';
import 'agent_cursor_registry.dart';
import 'agent_cursor_target.dart';

class AgentCursorController extends ChangeNotifier
    implements AgentCursorPerformer {
  AgentCursorController({
    AgentCursorRegistry? registry,
    this.travelDuration = const Duration(milliseconds: 520),
    this.maxTypingDuration = const Duration(milliseconds: 1500),
    this.appearTimeout = const Duration(milliseconds: 1500),
  }) : registry = registry ?? AgentCursorRegistry();

  final AgentCursorRegistry registry;
  final Duration travelDuration;
  final Duration maxTypingDuration;

  /// So lange wartet der Cursor auf ein noch nicht gebautes Ziel.
  final Duration appearTimeout;

  /// Wird vom Overlay gesetzt, wenn Nutzer:innen Animationen reduzieren.
  bool reduceMotion = false;

  Offset? _globalPosition;
  int _clickCount = 0;
  bool _isDisposed = false;

  Offset? get globalPosition => _globalPosition;
  int get clickCount => _clickCount;
  bool get isVisible => _globalPosition != null;
  Duration get _flight => reduceMotion ? Duration.zero : travelDuration;

  @override
  Future<void> moveTo(AgentCursorTarget target) async {
    final rect = await _settledRect(target);
    final context = registry.contextOf(target);
    if (rect == null || context == null || _isDisposed) return;
    if (context.mounted) {
      await Scrollable.ensureVisible(context, duration: _flight);
    }
    _globalPosition = registry.globalRectOf(target)?.center ?? rect.center;
    notifyListeners();
    await Future<void>.delayed(_flight);
  }

  @override
  Future<void> click(AgentCursorTarget target) async {
    await moveTo(target);
    if (!isVisible || _isDisposed) return;
    _clickCount++;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    registry.activate(target);
  }

  /// Wartet, bis das Ziel gebaut ist und sich nicht mehr bewegt (z. B. weil
  /// ein Panel noch einfährt). Gibt `null` zurück, wenn es nie erscheint.
  Future<Rect?> _settledRect(AgentCursorTarget target) async {
    const poll = Duration(milliseconds: 60);
    Rect? previous;
    for (var i = 0; i < appearTimeout.inMilliseconds ~/ 60; i++) {
      final rect = registry.globalRectOf(target);
      if (rect != null && rect == previous) return rect;
      previous = rect;
      await Future<void>.delayed(poll);
      if (_isDisposed) return null;
    }
    return previous;
  }

  @override
  Future<void> typeInto(
    AgentCursorTarget target,
    String text,
    AgentCursorTextChanged onTextChanged,
  ) async {
    await click(target);
    final chunk = math.max(1, (text.length / 90).ceil());
    final tick = reduceMotion || text.isEmpty
        ? Duration.zero
        : maxTypingDuration ~/ math.max(1, (text.length / chunk).ceil());
    for (var end = chunk; end < text.length; end += chunk) {
      await onTextChanged(text.substring(0, end));
      await Future<void>.delayed(tick);
    }
    await onTextChanged(text);
  }

  @override
  void hide() {
    if (_isDisposed || _globalPosition == null) return;
    _globalPosition = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
