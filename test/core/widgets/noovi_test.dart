import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';
import 'package:syscat2/core/widgets/noovi/noovi_thinking.dart';

double _top(WidgetTester tester) =>
    tester.getTopLeft(find.byType(NooviImage)).dy;

void main() {
  test('every pose has an image in the bundle', () async {
    for (final pose in NooviPose.values) {
      final data = await rootBundle.load(pose.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: pose.name);
    }
  });

  testWidgets('Noovi is decorative unless he gets a label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            NooviImage(pose: NooviPose.wave, size: 32),
            NooviImage(pose: NooviPose.cheer, size: 32, semanticLabel: 'Noovi'),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Noovi'), findsOneWidget);
    expect(tester.getSemantics(find.byType(Image).first).label, isEmpty);
    semantics.dispose();
  });

  testWidgets('thinking Noovi floats and says what he does', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: NooviThinking(size: 48))),
    );
    final start = _top(tester);
    await tester.pump(const Duration(milliseconds: 800));

    expect(_top(tester), isNot(start));
    expect(find.bySemanticsLabel('Noovi denkt nach …'), findsOneWidget);
  });

  testWidgets('thinking Noovi stands still when animations are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: NooviThinking(size: 48)),
        ),
      ),
    );
    final start = _top(tester);
    await tester.pump(const Duration(milliseconds: 800));

    expect(_top(tester), start);
  });
}
