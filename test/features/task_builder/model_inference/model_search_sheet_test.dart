import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_sheet.dart';

import 'model_catalog_test_support.dart';
import 'model_search_sheet_test_support.dart';

void main() {
  testWidgets('zeigt Katalog und eigene Modelle, filtert und liefert die '
      'Auswahl', (tester) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('ocr', title: 'Texterkennung'),
        modelEntry('cached', title: 'Gesichtserkennung'),
      ];
    final cubit = await loadedCatalogCubit(
      tester,
      repository,
      local: [
        modelEntry(
          'cached',
          title: 'Gesichtserkennung',
          origin: ModelOrigin.catalog,
        ),
        modelEntry('own', title: 'Mein Modell', origin: ModelOrigin.import),
      ],
    );
    ModelCatalogEntry? selected;
    await tester.pumpWidget(
      hostWithCatalog(
        cubit,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                selected = await showModelSearchSheet(context),
            child: const Text('Suchen'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Suchen'));
    await tester.pumpAndSettle();

    expect(find.text('Texterkennung'), findsOneWidget);
    expect(find.text('Gesichtserkennung'), findsOneWidget);
    expect(find.text('Gecacht'), findsOneWidget);
    expect(find.text('Eigenes Modell'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'text');
    await tester.pumpAndSettle();
    expect(find.text('Gesichtserkennung'), findsNothing);
    await tester.tap(find.text('Texterkennung'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'ocr');
  });

  testWidgets('meldet einen nicht erreichbaren Katalog und leere Treffer', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()..globalError = 'offline';
    final cubit = await loadedCatalogCubit(tester, repository);
    await tester.pumpWidget(
      hostWithCatalog(
        cubit,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModelSearchSheet(context),
            child: const Text('Suchen'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Suchen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nicht erreichbar'), findsOneWidget);
    expect(find.text('Kein Modell gefunden'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets(
    'erscheint am Desktop als Fenster-Sheet und schließt über Abbrechen',
    (tester) async {
      useWideDesktop(tester);
      final repository = FakeModelCatalogRepository()
        ..globalEntries = [modelEntry('ocr', title: 'Texterkennung')];
      final cubit = await loadedCatalogCubit(tester, repository);
      ModelCatalogEntry? selected = modelEntry('platzhalter');
      await openModelSearch(
        tester,
        cubit,
        onSelected: (value) => selected = value,
      );

      expect(find.byType(SheetFooter), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Texterkennung'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Modell auswählen'), findsNothing);
      expect(selected, isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('zeigt am Desktop die Filter als Spalte neben den Treffern', (
    tester,
  ) async {
    useWideDesktop(tester);
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('yolo', title: 'Yolo', task: ModelTask.objectDetection),
        modelEntry('piper', title: 'Piper', task: ModelTask.textToSpeech),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(tester, cubit);

    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsNothing);
    expect(filterOptionWithCount('Objekte erkennen', 1), findsOneWidget);
    await tapFilterOption(tester, 'Objekte erkennen');

    expect(find.text('Piper'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Objekte erkennen'), findsOneWidget);
    await tester.tap(find.byTooltip('Filter „Objekte erkennen“ entfernen'));
    await tester.pumpAndSettle();

    expect(find.text('Piper'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
