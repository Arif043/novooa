import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_graph_forces.dart';

/// Live-Kraftsimulation des Wissensgraphen: Notizen stoßen sich ab, Links
/// ziehen wie Federn, eine leichte Schwerkraft hält den Graph in der Mitte.
/// Die Temperatur [alpha] fällt mit jedem Schritt; Ziehen hält sie warm
/// ([alphaTarget]), sodass der ganze Graph reagiert und danach ausschwingt.
class KnowledgeGraphSimulation {
  KnowledgeGraphSimulation({
    required this.canvasSize,
    this.forces = const KnowledgeGraphForces(),
  });

  static const alphaMin = .001;
  static const _draggingAlpha = .3;
  static final _alphaDecay = 1 - math.pow(alphaMin, 1 / 300).toDouble();
  static const _velocityDecay = .4;
  static const _margin = 48.0;

  final KnowledgeGraphForces forces;
  Size canvasSize;
  final positions = <String, Offset>{};
  final _velocities = <String, Offset>{};
  final _links = <(String, String)>{};
  final degrees = <String, int>{};
  double alpha = 1;
  double alphaTarget = 0;
  String? _fixedId;

  /// Läuft, solange der Graph noch warm ist oder gezogen wird.
  bool get isActive => alpha >= alphaMin || alphaTarget > 0;

  /// Alle Links einmal, ohne Richtung, Duplikate und Selbstlinks.
  Iterable<(String, String)> get links => _links;

  /// Die Nachbarn einer Notiz über Links in beide Richtungen.
  Set<String> neighboursOf(String id) => {
    for (final (source, target) in _links)
      if (source == id) target else if (target == id) source,
  };

  /// Übernimmt den Notizbestand. Beim ersten Mal entfaltet sich der Graph aus
  /// einer Spirale; spätere neue Notizen starten neben einem Nachbarn.
  void setNotes(List<KnowledgeNote> notes) {
    final ids = {for (final note in notes) note.id};
    positions.removeWhere((id, _) => !ids.contains(id));
    _velocities.removeWhere((id, _) => !ids.contains(id));
    _rebuildLinks(notes, ids);
    final initial = positions.isEmpty;
    final added = [
      for (final note in notes)
        if (!positions.containsKey(note.id)) note.id,
    ];
    for (final (index, id) in added.indexed) {
      positions[id] = initial ? _spiral(index) : _besideNeighbour(id, index);
      _velocities[id] = Offset.zero;
    }
    if (added.isNotEmpty) alpha = math.max(alpha, initial ? 1 : _draggingAlpha);
  }

  /// Startet die Simulation neu aus der Spirale.
  void restart() {
    final ids = positions.keys.toList();
    for (final (index, id) in ids.indexed) {
      positions[id] = _spiral(index);
      _velocities[id] = Offset.zero;
    }
    alpha = 1;
  }

  void startDrag(String id) {
    _fixedId = id;
    alphaTarget = _draggingAlpha;
    alpha = math.max(alpha, _draggingAlpha);
  }

  void dragTo(String id, Offset position) {
    positions[id] = _clamp(position);
    _velocities[id] = Offset.zero;
  }

  /// Der losgelassene Knoten ist wieder frei und findet seinen Platz selbst.
  void endDrag() {
    _fixedId = null;
    alphaTarget = 0;
  }

  /// Ein fester Zeitschritt (1/60 s).
  void step() {
    alpha += (alphaTarget - alpha) * _alphaDecay;
    forces.applyRepulsion(positions, _velocities, alpha);
    forces.applyLinks(_links, degrees, positions, _velocities, alpha);
    forces.applyGravity(
      positions,
      _velocities,
      canvasSize.center(Offset.zero),
      alpha,
    );
    for (final id in positions.keys) {
      if (id == _fixedId) {
        _velocities[id] = Offset.zero;
        continue;
      }
      final velocity = _velocities[id]! * (1 - _velocityDecay);
      _velocities[id] = velocity;
      positions[id] = _clamp(positions[id]! + velocity);
    }
    forces.applyCollision(positions, {?_fixedId});
    positions.updateAll((_, position) => _clamp(position));
  }

  /// Rechnet ohne Animation bis zur Ruhe (reduzierte Bewegung).
  void settle() {
    for (var step = 0; step < 400 && isActive; step++) {
      this.step();
    }
  }

  void _rebuildLinks(List<KnowledgeNote> notes, Set<String> ids) {
    _links.clear();
    for (final note in notes) {
      for (final target in note.outgoingLinks) {
        if (target == note.id || !ids.contains(target)) continue;
        final pair = note.id.compareTo(target) < 0
            ? (note.id, target)
            : (target, note.id);
        _links.add(pair);
      }
    }
    degrees
      ..clear()
      ..addAll({for (final id in ids) id: 0});
    for (final (source, target) in _links) {
      degrees[source] = degrees[source]! + 1;
      degrees[target] = degrees[target]! + 1;
    }
  }

  /// Phyllotaxis-Spirale: gleichmäßig verteilt, ohne Überlappung am Start.
  Offset _spiral(int index) {
    final radius = 18 * math.sqrt(index + .5);
    final angle = index * math.pi * (3 - math.sqrt(5));
    return canvasSize.center(Offset.zero) +
        Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  Offset _besideNeighbour(String id, int index) {
    final neighbour = neighboursOf(id).where(positions.containsKey).firstOrNull;
    final anchor = neighbour == null
        ? canvasSize.center(Offset.zero)
        : positions[neighbour]!;
    final angle = index * 2.399;
    return _clamp(
      anchor +
          Offset(math.cos(angle), math.sin(angle)) * forces.linkDistance * .6,
    );
  }

  Offset _clamp(Offset value) => Offset(
    value.dx.clamp(_margin, canvasSize.width - _margin),
    value.dy.clamp(_margin, canvasSize.height - _margin),
  );
}
