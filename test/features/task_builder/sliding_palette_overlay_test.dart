import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/sliding_palette_overlay.dart';

Widget _app({required bool visible, VoidCallback? onDismiss}) {
  return MaterialApp(
    home: Stack(
      children: [
        SlidingPaletteOverlay(
          visible: visible,
          width: 200,
          onDismiss: onDismiss ?? () {},
          child: const ColoredBox(
            color: Colors.white,
            child: Text('Menü', key: Key('menu')),
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('zieht den umgebenden Stack nicht zusammen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: Stack(
              key: const Key('stack'),
              children: [
                Positioned.fill(child: Container()),
                SlidingPaletteOverlay(
                  visible: false,
                  width: 100,
                  onDismiss: () {},
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('stack'))),
      const Size(300, 400),
    );
  });

  testWidgets('ist zu Beginn nicht gebaut', (tester) async {
    await tester.pumpWidget(_app(visible: false));

    expect(find.byKey(const Key('menu')), findsNothing);
  });

  testWidgets('gleitet von links herein und wieder hinaus', (tester) async {
    await tester.pumpWidget(_app(visible: false));

    await tester.pumpWidget(_app(visible: true));
    await tester.pump(const Duration(milliseconds: 40));
    final entering = tester.getTopLeft(find.byKey(const Key('menu'))).dx;
    expect(entering, lessThan(0), reason: 'startet links außerhalb');

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('menu'))).dx, 0);

    await tester.pumpWidget(_app(visible: false));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('menu')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu')), findsNothing);
  });

  testWidgets('Tipp auf den abgedunkelten Hintergrund schließt', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      _app(visible: true, onDismiss: () => dismissed = true),
    );

    await tester.tapAt(const Offset(700, 300));

    expect(dismissed, isTrue);
  });
}
