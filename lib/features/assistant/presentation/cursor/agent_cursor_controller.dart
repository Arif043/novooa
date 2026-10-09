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
  }) : registry = registry ?? AgentCursorRegistry();

  final AgentCursorRegistry registry;
  final Duration travelDuration;
  final Duration maxTypingDuration;

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
    final context = registry.contextOf(target);
    if (context == null || !context.mounted) return;
    await Scrollable.ensureVisible(context, duration: _flight);
    final rect = registry.globalRectOf(target);
    if (rect == null || _isDisposed) return;
    _globalPosition = rect.center;
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
