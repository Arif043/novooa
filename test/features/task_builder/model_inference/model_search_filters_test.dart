import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_tag_vocabulary.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';

import 'model_catalog_test_support.dart';
import 'model_search_sheet_test_support.dart';

/// Schmaler Bildschirm (Standard im Test): Filter auf eigener Seite im Bottom Sheet.
void main() {
  testWidgets('grenzt nach Aufgabe ein und setzt Filter zurück', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('piper', title: 'Piper', task: ModelTask.textToSpeech),
        modelEntry('kokoro', title: 'Kokoro', task: ModelTask.textToSpeech),
        modelEntry('yolo', title: 'Yolo', task: ModelTask.objectDetection),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(tester, cubit);
    await openFilterPage(tester);

    expect(filterOptionWithCount('Text vorlesen', 2), findsOneWidget);
    await tapFilterOption(tester, 'Objekte erkennen');
    expect(find.text('Treffer anzeigen (1)'), findsOneWidget);
    await showMatches(tester);

    expect(find.text('Yolo'), findsOneWidget);
    expect(find.text('Piper'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Objekte erkennen'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'piper');
    await tester.pumpAndSettle();
    expect(find.text('Kein Modell gefunden'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Filter zurücksetzen'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Piper'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('zeigt in Sprach-Bausteinen keine Aufgaben', (tester) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('piper', task: ModelTask.textToSpeech, languages: ['de']),
        modelEntry('kokoro', task: ModelTask.textToSpeech, languages: ['en']),
        modelEntry('yolo', task: ModelTask.objectDetection),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(
      tester,
      cubit,
      speechDirection: SpeechModelDirection.textToSpeech,
    );
    await openFilterPage(tester);

    expect(find.textContaining('Objekte erkennen'), findsNothing);
    expect(filterOptionWithCount('Deutsch', 1), findsOneWidget);
    expect(filterOptionWithCount('Englisch', 1), findsOneWidget);
  });

  testWidgets('blendet bei vielen Aufgaben eine Bereichsebene ein und '
      'klappt lange Gruppen zusammen', (tester) async {
    final tasks = [
      ModelTask.objectDetection,
      ModelTask.opticalCharacterRecognition,
      ModelTask.imageSegmentation,
      ModelTask.depthEstimation,
      ModelTask.textToSpeech,
      ModelTask.automaticSpeechRecognition,
      ModelTask.textClassification,
    ];
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        for (final task in tasks)
          modelEntry(task.key, title: 'Modell ${task.key}', task: task),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(tester, cubit);
    await openFilterPage(tester);

    expect(filterOptionWithCount('Bild & Video', 4), findsOneWidget);
    expect(find.text('Alle anzeigen (7)'), findsOneWidget);
    await tapFilterOption(tester, 'Audio');

    expect(find.text('Alle anzeigen (7)'), findsNothing);
    expect(filterOptionWithCount('Text vorlesen', 1), findsOneWidget);
    expect(filterOption('Objekte erkennen'), findsNothing);
    await showMatches(tester);
    expect(find.text('Modell text-classification'), findsNothing);
  });

  testWidgets('filtert nach Themen und zeigt Tag-Bezeichnungen', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('dogs', title: 'Hunderassen', tags: ['pets']),
        modelEntry('scans', title: 'Belegscanner', tags: ['receipts']),
      ];
    final cubit = await loadedCatalogCubit(
      tester,
      repository,
      vocabulary: const ModelTagVocabulary([
        ModelTag(key: 'animals', labels: {'en': 'Animals', 'de': 'Tiere'}),
        ModelTag(
          key: 'pets',
          parent: 'animals',
          labels: {'en': 'Pets', 'de': 'Haustiere'},
        ),
        ModelTag(key: 'receipts', labels: {'en': 'Receipts', 'de': 'Belege'}),
      ]),
    );
    await openModelSearch(tester, cubit);

    // Tag-Bezeichnungen folgen wie Titel der Flutter-Locale (im Test en-US).
    expect(find.textContaining('Pets'), findsOneWidget);
    await openFilterPage(tester);
    expect(find.text('Themen'), findsOneWidget);
    await tapFilterOption(tester, 'Animals');
    await showMatches(tester);

    expect(find.text('Hunderassen'), findsOneWidget);
    expect(find.text('Belegscanner'), findsNothing);
  });

  testWidgets('zeigt bei wenigen Aufgaben keine Bereichsebene', (tester) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [
        modelEntry('a', task: ModelTask.objectDetection),
        modelEntry('b', task: ModelTask.textToSpeech),
      ];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(tester, cubit);
    await openFilterPage(tester);

    expect(find.text('Bereich'), findsNothing);
    expect(find.text('Aufgabe'), findsOneWidget);
  });

  testWidgets('blendet den Filter-Knopf ohne Auswahlmöglichkeit aus', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository()
      ..globalEntries = [modelEntry('a', task: ModelTask.objectDetection)];
    final cubit = await loadedCatalogCubit(tester, repository);
    await openModelSearch(tester, cubit);

    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsNothing);
  });
}
