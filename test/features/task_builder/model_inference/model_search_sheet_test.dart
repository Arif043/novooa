import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_sheet.dart';

import 'model_catalog_test_support.dart';

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
}
