import '../entities/scan_quad.dart';

/// Macht aus den einzelnen, verrauschten Erkennungen eine ruhige Kontur.
///
/// Die Erkennung liefert jedes Bild neu und schwankt um einige Pixel; ab und
/// zu trifft sie auch eine falsche Fläche oder nichts. Gezeigt wird deshalb
/// erst eine bestätigte Kontur, kleine Schwankungen werden geschluckt und
/// einzelne Ausreißer und Aussetzer übergangen.
class ScanQuadStabilizer {
  ScanQuadStabilizer({
    this.agreementDistance = 0.06,
    this.deadZone = 0.004,
    this.smoothing = 0.5,
    this.missesBeforeHiding = 5,
  });

  /// So weit (Anteil der Bildgröße) dürfen zwei Erkennungen auseinanderliegen
  /// und trotzdem dasselbe Blatt meinen.
  final double agreementDistance;

  /// Kleinere Bewegungen sind Rauschen; die Kontur bleibt dann stehen.
  final double deadZone;

  /// Anteil des Wegs zur neuen Erkennung, den die Kontur je Bild zurücklegt.
  final double smoothing;

  /// Nach so vielen Bildern ohne passende Erkennung verschwindet die Kontur.
  final int missesBeforeHiding;

  ScanQuad? _shown;
  ScanQuad? _candidate;
  int _misses = 0;

  /// Verarbeitet die Erkennung eines Bildes und liefert die anzuzeigende
  /// Kontur.
  ScanQuad? next(ScanQuad? detected) {
    final shown = _shown;
    if (detected == null) return _miss();
    if (shown == null) return _confirm(detected);
    if (!_agrees(shown, detected)) return _outlier(detected);
    _candidate = null;
    _misses = 0;
    return _shown = _follow(shown, detected);
  }

  void reset() {
    _shown = null;
    _candidate = null;
    _misses = 0;
  }

  ScanQuad? _confirm(ScanQuad detected) {
    final candidate = _candidate;
    if (candidate != null && _agrees(candidate, detected)) {
      _candidate = null;
      _misses = 0;
      return _shown = detected;
    }
    _candidate = detected;
    return null;
  }

  // Ein einzelner weit entfernter Treffer ist meist eine falsche Fläche; erst
  // ein zweiter an derselben Stelle zeigt, dass das Blatt dort liegt.
  ScanQuad? _outlier(ScanQuad detected) {
    final confirmed = _confirm(detected);
    return confirmed ?? _miss(keepCandidate: true);
  }

  ScanQuad? _miss({bool keepCandidate = false}) {
    if (!keepCandidate) _candidate = null;
    _misses++;
    if (_misses >= missesBeforeHiding) _shown = null;
    return _shown;
  }

  ScanQuad _follow(ScanQuad shown, ScanQuad detected) {
    if (shown.maxCornerDistance(detected) <= deadZone) return shown;
    return shown.lerp(detected, smoothing);
  }

  bool _agrees(ScanQuad a, ScanQuad b) {
    return a.maxCornerDistance(b) <= agreementDistance;
  }
}
