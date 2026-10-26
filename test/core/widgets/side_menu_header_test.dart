import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/root_side_menu_sections.dart';
import 'package:syscat2/generated/assets.dart';

import '../../helpers/test_translations.dart';

DateTime _at(int hour) => DateTime(2026, 10, 26, hour);

void main() {
  tearDown(() => loadTestTranslations(const Locale('de')));

  testWidgets('zeigt Logo und rechts daneben den Gruß mit dem Vornamen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SideMenuHeader(
          currentUserName: '  Arif  Ertugrul ',
          clock: () => _at(9),
        ),
        width: 800,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guten Morgen, Arif!'), findsOneWidget);
    expect(
      tester.getRect(find.byType(Text)).left,
      greaterThan(tester.getRect(find.byType(Image)).right),
    );
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, Assets.iconsFullv2Transparent);
    expect(logo.semanticLabel, 'novooa');
    expect(tester.takeException(), isNull);
  });

  for (final (hour, greeting) in [
    (4, 'Guten Abend'),
    (5, 'Guten Morgen'),
    (12, 'Guten Tag'),
    (18, 'Guten Abend'),
  ]) {
    testWidgets('grüßt um $hour Uhr mit „$greeting“', (tester) async {
      await tester.pumpWidget(
        _app(SideMenuHeader(currentUserName: 'Arif', clock: () => _at(hour))),
      );
      expect(find.text('$greeting, Arif!'), findsOneWidget);
    });
  }

  for (final entry in {
    'de': 'Guten Tag!',
    'en': 'Good afternoon!',
    'tr': 'İyi günler!',
  }.entries) {
    testWidgets('ohne Namen nur der Gruß in ${entry.key}', (tester) async {
      loadTestTranslations(Locale(entry.key));
      await tester.pumpWidget(
        _app(SideMenuHeader(currentUserName: ' ', clock: () => _at(14))),
      );
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
      'langer Name bei großer Schrift und schmalem Menü (dark=$dark)',
      (tester) async {
        await tester.pumpWidget(
          _app(
            SideMenuHeader(
              currentUserName: 'Alexandra Maximiliane Musterfrau',
              clock: () => _at(20),
            ),
            dark: dark,
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();

        final name = find.text('Guten Abend, Alexandra!');
        expect(name, findsOneWidget);
        expect(tester.takeException(), isNull);
        final headerBounds = tester.getRect(find.byType(SideMenuHeader));
        expect(
          tester.getRect(name).right,
          lessThanOrEqualTo(headerBounds.right),
        );
      },
    );
  }
}

Widget _app(
  Widget header, {
  bool dark = false,
  double textScale = 1,
  double width = 240,
}) {
  return MaterialApp(
    theme: dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: header),
        ),
      ),
    ),
  );
}
