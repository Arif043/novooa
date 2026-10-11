import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/settings/presentation/widgets/adaptive_settings_tabs.dart';
import 'package:syscat2/features/settings/presentation/widgets/settings_tab_contribution.dart';

final _tabs = [
  SettingsTabContribution(
    icon: Icons.settings_outlined,
    labelKey: LocaleKeys.settings_tabs_general,
    builder: (_) => const Text('Inhalt Allgemein'),
  ),
  SettingsTabContribution(
    icon: Icons.link,
    labelKey: LocaleKeys.settings_tabs_connections,
    builder: (_) => const Text('Inhalt Verbindungen'),
  ),
];

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdaptiveSettingsTabs(tabs: _tabs)),
    ),
  );
}

void main() {
  testWidgets('auf Mobile zeigt eine Liste alle Bereiche mit Text', (
    tester,
  ) async {
    await _pump(tester, 390);

    expect(find.text('Allgemein'), findsOneWidget);
    expect(find.text('Verbindungen'), findsOneWidget);
    expect(find.text('Inhalt Allgemein'), findsNothing);
  });

  testWidgets('auf Mobile öffnet ein Eintrag den Bereich, Zurück die Liste', (
    tester,
  ) async {
    await _pump(tester, 390);

    await tester.tap(find.text('Verbindungen'));
    await tester.pumpAndSettle();
    expect(find.text('Inhalt Verbindungen'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Inhalt Verbindungen'), findsNothing);
    expect(find.text('Allgemein'), findsOneWidget);
  });

  testWidgets('ab Tablet-Breite bleibt die Reiterleiste', (tester) async {
    await _pump(tester, 1024);

    expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);
    expect(find.text('Inhalt Allgemein'), findsOneWidget);
  });
}
