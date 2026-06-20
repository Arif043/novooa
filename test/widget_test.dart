import 'package:flutter_test/flutter_test.dart';

import 'package:syscat2/main.dart';

void main() {
  testWidgets('root page shows drawer tabs and updates content', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Übersicht der wichtigsten Kennzahlen.'), findsOneWidget);

    await tester.tap(find.byTooltip('Menü öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('Menü'), findsOneWidget);

    await tester.tap(find.text('Projekte'));
    await tester.pumpAndSettle();

    expect(find.text('Projekte'), findsWidgets);
    expect(find.text('Verwaltung und Status aller Projekte.'), findsOneWidget);
  });
}
