import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_generation_options_section.dart';

Future<List<PromptGenerationOptions>> _pump(
  WidgetTester tester, {
  required bool showContextWindow,
  PromptGenerationOptions options = const PromptGenerationOptions(),
}) async {
  final changes = <PromptGenerationOptions>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PromptGenerationOptionsSection(
            options: options,
            showContextWindow: showContextWindow,
            onChanged: changes.add,
          ),
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  testWidgets('bleibt eingeklappt, solange der Modellstandard gilt', (
    tester,
  ) async {
    await _pump(tester, showContextWindow: true);

    expect(find.text('Erweitert'), findsOneWidget);
    expect(find.text('Modellstandard'), findsOneWidget);
    expect(find.text('Kontextfenster (Tokens)'), findsNothing);
  });

  testWidgets('zeigt das Kontextfenster nur, wenn das Modell es kennt', (
    tester,
  ) async {
    await _pump(tester, showContextWindow: false);
    await tester.tap(find.text('Erweitert'));
    await tester.pumpAndSettle();

    expect(find.text('Max. Antwortlänge (Tokens)'), findsOneWidget);
    expect(find.text('Kontextfenster (Tokens)'), findsNothing);
  });

  testWidgets('ein eingetragenes Kontextfenster wird gemeldet', (tester) async {
    final changes = await _pump(tester, showContextWindow: true);
    await tester.tap(find.text('Erweitert'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kontextfenster (Tokens)'),
      '16384',
    );

    expect(changes.last.contextWindow, 16384);
  });

  testWidgets('gesetzte Optionen klappen den Bereich auf', (tester) async {
    await _pump(
      tester,
      showContextWindow: false,
      options: const PromptGenerationOptions().withContextWindow(8192),
    );

    expect(find.text('Eigene Einstellungen'), findsOneWidget);
    expect(find.text('Kontextfenster (Tokens)'), findsOneWidget);
  });
}
