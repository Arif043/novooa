import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/document_scan/domain/entities/scan_quad.dart';
import 'package:syscat2/features/document_scan/domain/services/scan_quad_stabilizer.dart';

import 'fake_document_scanner.dart';

/// [documentQuad], um [dx] nach rechts verschoben.
ScanQuad _shifted(double dx) {
  return ScanQuad.fromCorners([
    for (final corner in documentQuad.corners)
      ScanPoint(corner.x + dx, corner.y),
  ]);
}

/// Bringt den Stabilisierer in den Zustand „Kontur sichtbar“.
ScanQuadStabilizer _showing(ScanQuad quad) {
  return ScanQuadStabilizer()
    ..next(quad)
    ..next(quad);
}

void main() {
  test('zeigt eine Kontur erst, wenn zwei Erkennungen übereinstimmen', () {
    final stabilizer = ScanQuadStabilizer();

    expect(stabilizer.next(documentQuad), isNull);
    expect(stabilizer.next(_shifted(0.01)), _shifted(0.01));
  });

  test('zwei weit auseinanderliegende Erkennungen bestätigen nichts', () {
    final stabilizer = ScanQuadStabilizer();

    expect(stabilizer.next(documentQuad), isNull);
    expect(stabilizer.next(_shifted(0.2)), isNull);
  });

  test('kleine Schwankungen lassen die Kontur stillstehen', () {
    final stabilizer = _showing(documentQuad);

    expect(stabilizer.next(_shifted(0.003)), documentQuad);
    expect(stabilizer.next(_shifted(-0.003)), documentQuad);
  });

  test('größere Bewegungen folgt die Kontur geglättet zur Hälfte', () {
    final stabilizer = _showing(documentQuad);

    final shown = stabilizer.next(_shifted(0.04))!;

    expect(shown.topLeft.x, closeTo(documentQuad.topLeft.x + 0.02, 1e-9));
  });

  test('ein einzelner Ausreißer verschiebt die Kontur nicht', () {
    final stabilizer = _showing(documentQuad);

    expect(stabilizer.next(_shifted(0.3)), documentQuad);
    expect(stabilizer.next(documentQuad), documentQuad);
  });

  test('ein bestätigter Ausreißer ist ein neues Blatt und wird übernommen', () {
    final stabilizer = _showing(documentQuad);

    stabilizer.next(_shifted(0.15));

    expect(stabilizer.next(_shifted(0.15)), _shifted(0.15));
  });

  test('kurze Aussetzer überbrückt, nach fünf Fehlbildern ausgeblendet', () {
    final stabilizer = _showing(documentQuad);

    for (var miss = 1; miss < 5; miss++) {
      expect(stabilizer.next(null), documentQuad, reason: 'Fehlbild $miss');
    }
    expect(stabilizer.next(null), isNull);
  });

  test('ein Treffer setzt die Zählung der Fehlbilder zurück', () {
    final stabilizer = _showing(documentQuad);
    for (var miss = 0; miss < 4; miss++) {
      stabilizer.next(null);
    }

    stabilizer.next(documentQuad);

    expect(stabilizer.next(null), documentQuad);
  });

  test('reset vergisst Kontur und Kandidaten', () {
    final stabilizer = _showing(documentQuad)..reset();

    expect(stabilizer.next(documentQuad), isNull);
  });
}
