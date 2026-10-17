import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/document_scan/domain/entities/scan_quad.dart';
import 'package:syscat2/features/document_scan/presentation/widgets/scan_quad_overlay.dart';

import 'fake_document_scanner.dart';

final _movedQuad = ScanQuad.fromCorners([
  for (final corner in documentQuad.corners)
    ScanPoint(corner.x + 0.1, corner.y),
]);

Widget _overlay(ScanQuad? quad) {
  return MaterialApp(home: ScanQuadOverlay(quad: quad));
}

TweenAnimationBuilder<ScanQuad> _glide(WidgetTester tester) {
  return tester.widget(find.byType(TweenAnimationBuilder<ScanQuad>));
}

double _opacity(WidgetTester tester) {
  return tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
}

void main() {
  testWidgets('ohne Kontur wird nichts gezeichnet', (tester) async {
    await tester.pumpWidget(_overlay(null));

    expect(
      find.descendant(
        of: find.byType(ScanQuadOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('die Kontur gleitet zur neuen Lage, statt zu springen', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(documentQuad));
    await tester.pumpWidget(_overlay(_movedQuad));

    expect(_glide(tester).tween.end, _movedQuad);
    expect(_glide(tester).duration, ScanQuadOverlay.glideDuration);
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('ohne Erkennung verblasst die Kontur an ihrem Platz', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(documentQuad));
    await tester.pumpWidget(_overlay(null));

    expect(_opacity(tester), 0);
    expect(_glide(tester).tween.end, documentQuad);
    await tester.pumpAndSettle();
    expect(find.byType(TweenAnimationBuilder<ScanQuad>), findsOneWidget);
  });
}
