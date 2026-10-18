import 'package:flutter/scheduler.dart';

import 'knowledge_graph_simulation.dart';

/// Treibt die Simulation in festen Schritten von 1/60 s an, unabhängig von
/// der Bildrate, und hält an, sobald der Graph zur Ruhe gekommen ist.
class KnowledgeGraphSimulationTicker {
  KnowledgeGraphSimulationTicker({
    required TickerProvider vsync,
    required this.simulation,
    required this.onFrame,
  }) {
    _ticker = vsync.createTicker(_tick);
  }

  static const _stepSeconds = 1 / 60;

  final KnowledgeGraphSimulation simulation;
  final void Function() onFrame;
  late final Ticker _ticker;
  Duration _previous = Duration.zero;
  double _pendingSeconds = 0;

  void ensureRunning() {
    if (_ticker.isActive || !simulation.isActive) return;
    _previous = Duration.zero;
    _pendingSeconds = 0;
    _ticker.start();
  }

  void stop() => _ticker.stop();

  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _previous).inMicroseconds / 1000000;
    _previous = elapsed;
    // Nach einer Pause (Tab im Hintergrund) nicht alles auf einmal nachholen.
    _pendingSeconds += seconds.clamp(0, 1 / 15);
    if (_pendingSeconds < _stepSeconds) return;
    while (_pendingSeconds >= _stepSeconds) {
      simulation.step();
      _pendingSeconds -= _stepSeconds;
    }
    if (!simulation.isActive) _ticker.stop();
    onFrame();
  }
}
