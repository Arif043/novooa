import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/root_side_menu_sections.dart';
import 'package:syscat2/generated/assets.dart';

import '../../helpers/test_translations.dart';

void main() {
  tearDown(() => loadTestTranslations(const Locale('de')));

  testWidgets('zeigt Logo und begrüßt den Runtime-Nutzer', (tester) async {
    await tester.pumpWidget(
      _app(const SideMenuHeader(currentUserName: '  Arif  ')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hallo, Arif!'), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, Assets.iconsFullv2Transparent);
    expect(logo.semanticLabel, 'novooa');
    expect(tester.takeException(), isNull);
  });

  for (final entry in {
    'de': 'Hallo!',
    'en': 'Hello!',
    'tr': 'Merhaba!',
  }.entries) {
    testWidgets('zeigt eine Begrüßung ohne leeren Namen in ${entry.key}', (
      tester,
    ) async {
      loadTestTranslations(Locale(entry.key));
      await tester.pumpWidget(_app(const SideMenuHeader(currentUserName: ' ')));
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
      'langer Name bei großer Schrift und schmalem Menü (dark=$dark)',
      (tester) async {
        await tester.pumpWidget(
          _app(
            const SideMenuHeader(
              currentUserName: 'Alexandra Maximiliane Musterfrau',
            ),
            dark: dark,
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Hallo, Alexandra Maximiliane Musterfrau!'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        final textBounds = tester.getRect(find.byType(Text));
        final headerBounds = tester.getRect(find.byType(SideMenuHeader));
        expect(textBounds.right, lessThanOrEqualTo(headerBounds.right));
      },
    );
  }
}

Widget _app(Widget header, {bool dark = false, double textScale = 1}) {
  return MaterialApp(
    theme: dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 240, child: header),
        ),
      ),
    ),
  );
}
