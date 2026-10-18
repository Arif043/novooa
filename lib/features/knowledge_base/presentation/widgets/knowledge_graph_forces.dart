import 'dart:math' as math;
import 'dart:ui';

/// Die Kräfte der Wissensgraph-Simulation (nach d3-force). Jede Kraft
/// verändert Geschwindigkeiten und wird mit der Temperatur `alpha` skaliert:
/// heiß bewegt sich der Graph kräftig, abgekühlt kommt er zur Ruhe.
class KnowledgeGraphForces {
  const KnowledgeGraphForces({
    this.repulsion = 900,
    this.repulsionRange = 520,
    this.linkDistance = 120,
    this.gravity = .03,
    this.collisionRadius = 34,
  });

  /// Stärke, mit der sich zwei Knoten abstoßen.
  final double repulsion;

  /// Weiter entfernte Knoten stoßen sich nicht mehr ab; so treiben
  /// unverbundene Gruppen nicht endlos auseinander.
  final double repulsionRange;

  /// Ruhelänge einer Link-Feder.
  final double linkDistance;

  /// Zug zur Mitte, damit der Graph zusammenbleibt.
  final double gravity;

  /// Halber Mindestabstand zweier Knoten, damit sich Labels nicht überdecken.
  final double collisionRadius;

  void applyRepulsion(
    Map<String, Offset> positions,
    Map<String, Offset> velocities,
    double alpha,
  ) {
    final ids = positions.keys.toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final vector = positions[ids[i]]! - positions[ids[j]]!;
        final distance = vector.distance;
        if (distance > repulsionRange) continue;
        final push =
            _directionOf(vector, i, j) *
            (repulsion * alpha / math.max(distance, 12));
        velocities[ids[i]] = velocities[ids[i]]! + push;
        velocities[ids[j]] = velocities[ids[j]]! - push;
      }
    }
  }

  /// Federn ziehen auf die Ruhelänge; Knoten mit vielen Links geben weniger
  /// nach (Stärke und Verteilung nach Grad), damit Knotenpunkte ruhig bleiben.
  void applyLinks(
    Iterable<(String, String)> links,
    Map<String, int> degrees,
    Map<String, Offset> positions,
    Map<String, Offset> velocities,
    double alpha,
  ) {
    for (final (source, target) in links) {
      final vector =
          (positions[target]! + velocities[target]!) -
          (positions[source]! + velocities[source]!);
      final distance = math.max(vector.distance, 1.0);
      final sourceDegree = degrees[source]!;
      final targetDegree = degrees[target]!;
      final strength = 1 / math.min(sourceDegree, targetDegree);
      final pull =
          vector * ((distance - linkDistance) / distance * alpha * strength);
      final bias = sourceDegree / (sourceDegree + targetDegree);
      velocities[target] = velocities[target]! - pull * bias;
      velocities[source] = velocities[source]! + pull * (1 - bias);
    }
  }

  void applyGravity(
    Map<String, Offset> positions,
    Map<String, Offset> velocities,
    Offset center,
    double alpha,
  ) {
    for (final id in positions.keys) {
      velocities[id] =
          velocities[id]! + (center - positions[id]!) * (gravity * alpha);
    }
  }

  /// Schiebt überlappende Knoten direkt auseinander, unabhängig von `alpha`.
  void applyCollision(Map<String, Offset> positions, Set<String> fixed) {
    final ids = positions.keys.toList();
    final minimum = collisionRadius * 2;
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final vector = positions[ids[i]]! - positions[ids[j]]!;
        final distance = vector.distance;
        if (distance >= minimum) continue;
        final shift = _directionOf(vector, i, j) * ((minimum - distance) * .35);
        if (!fixed.contains(ids[i])) {
          positions[ids[i]] = positions[ids[i]]! + shift;
        }
        if (!fixed.contains(ids[j])) {
          positions[ids[j]] = positions[ids[j]]! - shift;
        }
      }
    }
  }

  /// Liegen zwei Knoten aufeinander, gibt ihr Index eine feste Richtung vor.
  Offset _directionOf(Offset vector, int i, int j) {
    final distance = vector.distance;
    if (distance > .01) return vector / distance;
    final angle = (i * 7 + j * 13) * .7;
    return Offset(math.cos(angle), math.sin(angle));
  }
}
