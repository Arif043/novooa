import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/presentation/widgets/detail/file_version_tile.dart';
import 'package:syscat2/features/files/presentation/widgets/detail/old_version_banner.dart';
import 'package:syscat2/features/files/presentation/widgets/detail/rename_file_dialog.dart';

import '../../support/fake_file_repositories.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('de'),
  supportedLocales: const [Locale('de')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  group('Versionskachel', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required bool isCurrent,
      int? sizeDelta,
    }) => tester.pumpWidget(
      _app(
        FileVersionTile(
          version: testVersion('version.1', sizeBytes: 2048),
          isCurrent: isCurrent,
          isSelected: false,
          sizeDelta: sizeDelta,
          onShow: () {},
          onDownload: () {},
          onRestore: () {},
        ),
      ),
    );

    testWidgets('die aktuelle Version trägt „Aktuell“ und lässt sich nicht '
        'wiederherstellen', (tester) async {
      await pumpTile(tester, isCurrent: true, sizeDelta: 1024);

      expect(find.text('Aktuell'), findsOneWidget);
      expect(find.textContaining('2 KB (+1 KB)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('Diese Version herunterladen'), findsOneWidget);
      expect(find.text('Wiederherstellen'), findsNothing);
    });

    testWidgets('eine ältere Version bietet Wiederherstellen an', (
      tester,
    ) async {
      await pumpTile(tester, isCurrent: false);

      expect(find.text('Aktuell'), findsNothing);
      expect(find.textContaining('(erste Version)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('Wiederherstellen'), findsOneWidget);
    });
  });

  testWidgets('der Hinweis zu einer alten Version führt zurück oder stellt '
      'sie wieder her', (tester) async {
    var restored = false;
    var showedCurrent = false;
    await tester.pumpWidget(
      _app(
        OldVersionBanner(
          version: testVersion('version.1', day: 20),
          onRestore: () => restored = true,
          onShowCurrent: () => showedCurrent = true,
        ),
      ),
    );

    expect(find.textContaining('20.10.2026'), findsOneWidget);
    await tester.tap(find.text('Zur aktuellen Version'));
    await tester.tap(find.text('Wiederherstellen'));
    expect((restored, showedCurrent), (true, true));
  });

  group('Umbenennen', () {
    Future<void> openDialog(
      WidgetTester tester,
      Future<FileFailureKind?> Function(String) onSubmit,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showRenameFileDialog(
                context,
                currentName: 'Bericht.txt',
                onSubmit: onSubmit,
              ),
              child: const Text('öffnen'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
    }

    testWidgets('ein vergebener Name bleibt mit Hinweis im Dialog', (
      tester,
    ) async {
      await openDialog(tester, (_) async => FileFailureKind.nameTaken);

      await tester.enterText(find.byType(TextField), 'Belegt.txt');
      await tester.tap(find.widgetWithText(FilledButton, 'Umbenennen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'In diesem Verzeichnis gibt es schon eine Datei mit diesem Namen.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ein gültiger neuer Name schließt den Dialog', (tester) async {
      String? submitted;
      await openDialog(tester, (name) async {
        submitted = name;
        return null;
      });

      await tester.enterText(find.byType(TextField), 'Protokoll.txt');
      await tester.tap(find.widgetWithText(FilledButton, 'Umbenennen'));
      await tester.pumpAndSettle();

      expect(submitted, 'Protokoll.txt');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('der Basisname ist vorausgewählt, die Endung nicht', (
      tester,
    ) async {
      await openDialog(tester, (_) async => null);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.selection.textInside(field.controller!.text),
        'Bericht',
      );
    });
  });
}
