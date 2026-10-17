import 'dart:math' as math;

/// Ein Punkt im Kamerabild als Anteil der Bildbreite und -höhe (0 bis 1).
class ScanPoint {
  const ScanPoint(this.x, this.y);

  final double x;
  final double y;

  ScanPoint lerp(ScanPoint other, double t) {
    return ScanPoint(x + (other.x - x) * t, y + (other.y - y) * t);
  }

  double distanceTo(ScanPoint other) {
    return math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));
  }

  @override
  bool operator ==(Object other) {
    return other is ScanPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

/// Die vier Ecken des erkannten Dokuments, im Uhrzeigersinn ab links oben.
class ScanQuad {
  const ScanQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Erwartet acht Werte (x, y je Ecke) im Bereich 0 bis 1; alles andere ist
  /// keine Erkennung.
  static ScanQuad? fromValues(List<double> values) {
    if (values.length != 8) return null;
    if (values.any((value) => value.isNaN || value < 0 || value > 1)) {
      return null;
    }
    ScanPoint at(int index) => ScanPoint(values[index], values[index + 1]);
    return ScanQuad.fromCorners([at(0), at(2), at(4), at(6)]);
  }

  /// Erwartet die vier Ecken in der Reihenfolge von [corners].
  factory ScanQuad.fromCorners(List<ScanPoint> corners) {
    return ScanQuad(
      topLeft: corners[0],
      topRight: corners[1],
      bottomRight: corners[2],
      bottomLeft: corners[3],
    );
  }

  final ScanPoint topLeft;
  final ScanPoint topRight;
  final ScanPoint bottomRight;
  final ScanPoint bottomLeft;

  List<ScanPoint> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  /// Der Weg von hier nach [other] beim Anteil [t] (0 = hier, 1 = [other]).
  ScanQuad lerp(ScanQuad other, double t) {
    final targets = other.corners;
    return ScanQuad.fromCorners([
      for (final (index, corner) in corners.indexed)
        corner.lerp(targets[index], t),
    ]);
  }

  /// Wie weit die am stärksten verschobene Ecke von [other] entfernt ist.
  double maxCornerDistance(ScanQuad other) {
    final targets = other.corners;
    return corners.indexed
        .map((entry) => entry.$2.distanceTo(targets[entry.$1]))
        .reduce(math.max);
  }

  @override
  bool operator ==(Object other) {
    return other is ScanQuad &&
        other.topLeft == topLeft &&
        other.topRight == topRight &&
        other.bottomRight == bottomRight &&
        other.bottomLeft == bottomLeft;
  }

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);
}
