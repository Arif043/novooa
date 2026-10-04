/// Ein Punkt im Kamerabild als Anteil der Bildbreite und -höhe (0 bis 1).
class ScanPoint {
  const ScanPoint(this.x, this.y);

  final double x;
  final double y;
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
    return ScanQuad(
      topLeft: at(0),
      topRight: at(2),
      bottomRight: at(4),
      bottomLeft: at(6),
    );
  }

  final ScanPoint topLeft;
  final ScanPoint topRight;
  final ScanPoint bottomRight;
  final ScanPoint bottomLeft;

  List<ScanPoint> get corners => [topLeft, topRight, bottomRight, bottomLeft];
}
