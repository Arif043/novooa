import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/output_canvas_toggle.dart';

void main() {
  Future<List<bool>> tapToggle(WidgetTester tester, bool showOnCanvas) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutputCanvasToggle(
            showOnCanvas: showOnCanvas,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    return changes;
  }

  testWidgets('holt einen Wert auf die Leinwand', (tester) async {
    expect(await tapToggle(tester, false), [true]);
    expect(find.byTooltip('Auf der Leinwand zeigen'), findsOneWidget);
  });

  testWidgets('nimmt einen sichtbaren Wert von der Leinwand', (tester) async {
    expect(await tapToggle(tester, true), [false]);
    expect(find.byTooltip('Von der Leinwand nehmen'), findsOneWidget);
  });
}
