import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_field.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_groups.dart';

void main() {
  final models = [
    _model(
      'm1',
      'Gemini Flash',
      'gemini-flash',
      LanguageModelProvider.googleAi,
    ),
    _model('m2', 'Gemini Pro', 'gemini-pro', LanguageModelProvider.googleAi),
    _model(
      'm3',
      'Mistral Small',
      'mistral-small',
      LanguageModelProvider.mistral,
    ),
    _model('m4', 'Altes Modell', 'legacy', null),
  ];

  test(
    'gruppiert nach Anbieter in fester Reihenfolge, Unbekanntes zuletzt',
    () {
      final groups = groupModelsByProvider(models);

      expect(groups.map((group) => group.label), [
        'Google AI',
        'Mistral AI',
        'Weitere Modelle',
      ]);
      expect(groups.first.models.map((model) => model.id), ['m1', 'm2']);
      expect(groups.first.contains('m2'), isTrue);
      expect(groupModelsByProvider(const []), isEmpty);
    },
  );

  testWidgets('wählt erst den Anbieter, dann das Modell', (tester) async {
    String? picked;
    await tester.pumpWidget(_host(models, '', (value) => picked = value));

    expect(find.text('Standardmodell verwenden'), findsOneWidget);
    await tester.tap(find.text('Sprachmodell'));
    await tester.pumpAndSettle();

    expect(find.text('Anbieter'), findsWidgets);
    expect(find.text('Google AI'), findsOneWidget);
    expect(find.text('2 Modelle'), findsOneWidget);
    expect(
      find.text('Gemini Pro'),
      findsNothing,
      reason: 'Modelle erst im 2. Schritt',
    );

    await tester.tap(find.text('Google AI'));
    await tester.pumpAndSettle();
    expect(find.text('Gemini Pro'), findsOneWidget);
    expect(find.text('Mistral Small'), findsNothing);

    await tester.tap(find.text('Gemini Pro'));
    await tester.pumpAndSettle();

    expect(picked, 'm2');
    expect(
      find.text('Anbieter'),
      findsNothing,
      reason: 'Sheet ist geschlossen',
    );
  });

  testWidgets('zeigt in der Anbieterauswahl das Logo je Anbieter', (
    tester,
  ) async {
    await tester.pumpWidget(_host(models, '', (_) {}));

    expect(find.byIcon(SimpleIcons.googlegemini), findsNothing);
    await tester.tap(find.text('Sprachmodell'));
    await tester.pumpAndSettle();

    expect(find.byIcon(SimpleIcons.googlegemini), findsOneWidget);
    expect(find.byIcon(SimpleIcons.mistralai), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
  });

  testWidgets('das Feld zeigt das Logo des gewählten Anbieters', (
    tester,
  ) async {
    await tester.pumpWidget(_host(models, 'm3', (_) {}));

    expect(find.byIcon(SimpleIcons.mistralai), findsOneWidget);
    expect(find.byIcon(SimpleIcons.googlegemini), findsNothing);
  });

  testWidgets(
    'zeigt die aktuelle Wahl mit Anbieter und erlaubt das Standardmodell',
    (tester) async {
      String? picked;
      await tester.pumpWidget(_host(models, 'm3', (value) => picked = value));

      expect(find.text('Mistral Small · Mistral AI'), findsOneWidget);

      await tester.tap(find.text('Sprachmodell'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standardmodell verwenden').last);
      await tester.pumpAndSettle();

      expect(picked, '');
    },
  );

  testWidgets('Abbrechen schließt das Sheet ohne Änderung', (tester) async {
    String? picked;
    await tester.pumpWidget(_host(models, 'm1', (value) => picked = value));

    await tester.tap(find.text('Sprachmodell'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('Anbieter'), findsNothing);
  });

  group('Desktop (macOS-Sheet)', () {
    testWidgets('wählt Anbieter und Modell mit Fußzeile statt Bottom Sheet', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(_host(models, '', (value) => picked = value));

      await tester.tap(find.text('Sprachmodell'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Zurück'), findsNothing, reason: 'erster Schritt');

      await tester.tap(find.text('Google AI'));
      await tester.pumpAndSettle();
      expect(find.text('Zurück'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Übernehmen'), findsNothing);

      await tester.tap(find.text('Zurück'));
      await tester.pumpAndSettle();
      expect(find.text('Google AI'), findsOneWidget);
      expect(
        find.text('Gemini Pro'),
        findsNothing,
        reason: 'Zurück schließt nicht',
      );

      await tester.tap(find.text('Google AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gemini Flash'));
      await tester.pumpAndSettle();

      expect(picked, 'm1');
      expect(find.text('Anbieter'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('Abbrechen und Escape schließen ohne Änderung', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(models, 'm1', (value) => picked = value));

      await tester.tap(find.text('Sprachmodell'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(find.text('Anbieter'), findsNothing);

      await tester.tap(find.text('Sprachmodell'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.text('Anbieter'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  testWidgets('die Beschriftung der Standard-Option ist anpassbar', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageModelPickerField(
            models: models,
            selectedModelId: '',
            defaultOptionLabel: 'Systemvorgabe verwenden',
            onChanged: (value) => picked = value,
          ),
        ),
      ),
    );

    expect(find.text('Systemvorgabe verwenden'), findsOneWidget);
    await tester.tap(find.text('Sprachmodell'));
    await tester.pumpAndSettle();
    expect(find.text('Standardmodell verwenden'), findsNothing);
    await tester.tap(find.text('Google AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gemini Flash'));
    await tester.pumpAndSettle();

    expect(picked, 'm1');
  });

  testWidgets('ein deaktiviertes Feld öffnet kein Sheet', (tester) async {
    await tester.pumpWidget(_host(const [], '', (_) {}, enabled: false));

    await tester.tap(find.text('Sprachmodell'));
    await tester.pumpAndSettle();

    expect(find.text('Anbieter'), findsNothing);
  });

  testWidgets('lange Modellnamen laufen im schmalen Feld nicht über', (
    tester,
  ) async {
    final long = _model(
      'm9',
      'Gemini 3.8 Flash Lite TTS',
      'gemini-3.8-flash-lite-tts',
      LanguageModelProvider.googleAi,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: LanguageModelPickerField(
                models: [long],
                selectedModelId: 'm9',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Widget _host(
  List<LanguageModel> models,
  String selected,
  ValueChanged<String> onChanged, {
  bool enabled = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LanguageModelPickerField(
          models: models,
          selectedModelId: selected,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

LanguageModel _model(
  String id,
  String name,
  String modelId,
  LanguageModelProvider? provider,
) {
  return LanguageModel(
    id: id,
    name: name,
    modelId: modelId,
    supportsImageInput: false,
    supportsStructuredOutput: true,
    supportsImageGeneration: false,
    provider: provider,
  );
}
