import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';
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

  testWidgets('grenzt per Chip nach Aufgabe ein und setzt Filter zurück', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry(
          'piper',
          title: 'Piper',
          task: ModelTask.textToSpeech,
          languages: ['de'],
        ),
        modelEntry(
          'kokoro',
          title: 'Kokoro',
          task: ModelTask.textToSpeech,
          languages: ['en'],
        ),
        modelEntry('yolo', title: 'Yolo', task: ModelTask.objectDetection),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await _openSheet(tester, cubit);

    expect(find.widgetWithText(FilterChip, 'Text vorlesen 2'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Objekte erkennen 1'));
    await tester.pumpAndSettle();
    expect(find.text('Yolo'), findsOneWidget);
    expect(find.text('Piper'), findsNothing);

    await tester.enterText(find.byType(TextField), 'piper');
    await tester.pumpAndSettle();
    expect(find.text('Kein Modell gefunden'), findsOneWidget);
    await tester.tap(find.text('Filter zurücksetzen'));
    await tester.pumpAndSettle();

    expect(find.text('Piper'), findsOneWidget);
  });

  testWidgets('zeigt in Sprach-Bausteinen keine Aufgaben-Chips', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('piper', task: ModelTask.textToSpeech, languages: ['de']),
        modelEntry('kokoro', task: ModelTask.textToSpeech, languages: ['en']),
        modelEntry('yolo', task: ModelTask.objectDetection),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await _openSheet(
      tester,
      cubit,
      speechDirection: SpeechModelDirection.textToSpeech,
    );

    expect(find.textContaining('Objekte erkennen'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Deutsch 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Englisch 1'), findsOneWidget);
  });

  testWidgets('blendet bei vielen Aufgaben eine Bereichsebene ein', (
    tester,
  ) async {
    final tasks = [
      ModelTask.objectDetection,
      ModelTask.opticalCharacterRecognition,
      ModelTask.imageSegmentation,
      ModelTask.depthEstimation,
      ModelTask.textToSpeech,
      ModelTask.automaticSpeechRecognition,
      ModelTask.translation,
    ];
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        for (final task in tasks)
          modelEntry(task.key, title: 'Modell ${task.key}', task: task),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await _openSheet(tester, cubit);

    expect(find.widgetWithText(FilterChip, 'Bild & Video 4'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Audio 2'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Text vorlesen 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Objekte erkennen 1'), findsNothing);
    expect(find.text('Modell translation'), findsNothing);
  });

  testWidgets('zeigt bei wenigen Aufgaben keine Bereichsebene', (tester) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('a', task: ModelTask.objectDetection),
        modelEntry('b', task: ModelTask.textToSpeech),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await _openSheet(tester, cubit);

    expect(find.text('Bereich'), findsNothing);
    expect(find.text('Aufgabe'), findsOneWidget);
  });
}

Future<void> _openSheet(
  WidgetTester tester,
  ModelCatalogCubit cubit, {
  SpeechModelDirection? speechDirection,
}) async {
  await tester.pumpWidget(
    hostWithCatalog(
      cubit,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showModelSearchSheet(context, speechDirection: speechDirection),
          child: const Text('Suchen'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Suchen'));
  await tester.pumpAndSettle();
}
