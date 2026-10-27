import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/root_app_bar.dart';
import 'package:syscat2/core/widgets/root_navigation.dart';

void main() {
  test('nur Seiten mit eigenem Kopf lassen den Titel der Leiste weg', () {
    final withHeader = [
      for (final tab in rootTabs())
        if (tab.hasPageHeader) tab.path,
    ];

    expect(withHeader, ['/schedule', '/files', '/skills', '/employees']);
  });

  testWidgets('zeigt ohne Titel nur Menü und Aktionen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: RootAppBar(
            onMenuPressed: () {},
            actions: const [Icon(Icons.notifications_none)],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Menü öffnen'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
