import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syscat2/main.dart';

void main() {
  testWidgets('task builder adds workflow primitives', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bausteine'), findsOneWidget);
    expect(find.text('Conditional Flow'), findsWidgets);

    await tester.tap(find.text('Tool Call'));
    await tester.pumpAndSettle();

    expect(find.text('4 Nodes'), findsOneWidget);
    expect(find.text('defineTool'), findsOneWidget);
  });
}
