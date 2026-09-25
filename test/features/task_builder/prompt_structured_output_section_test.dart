import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_structured_output_section.dart';

// Deckt den neuen Typ-Dropdown pro strukturiertem Ausgabefeld ab. Prüft
// insbesondere die Korrektur eines latenten Bugs: `_emit` (Name-/
// Beschreibungs-Textfelder) baute vorher ein komplett neues
// `StructuredOutputField` ohne den bestehenden Typ — jede Texteingabe hätte
// den zuvor gewählten Typ still auf `string` zurückgesetzt.
void main() {
  testWidgets('zeigt den aktuellen Typ im Dropdown an', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptStructuredOutputSection(
            fields: const [
              StructuredOutputField(
                name: 'summe',
                description: '',
                type: StructuredFieldType.number,
              ),
            ],
            onChanged: (_, _) {},
            onAdd: () {},
            onRemove: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Zahl'), findsOneWidget);
  });

  testWidgets(
    'Bearbeiten des Namens behält den zuvor gewählten Typ bei '
    '(Regression: _emit setzte den Typ zuvor still auf string zurück)',
    (tester) async {
      StructuredOutputField? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptStructuredOutputSection(
              fields: const [
                StructuredOutputField(
                  name: 'summe',
                  description: '',
                  type: StructuredFieldType.boolean,
                ),
              ],
              onChanged: (_, updated) => changed = updated,
              onAdd: () {},
              onRemove: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Feldname'),
        'bezahlt',
      );

      expect(changed?.name, 'bezahlt');
      expect(changed?.type, StructuredFieldType.boolean);
    },
  );

  testWidgets('Auswahl eines neuen Typs im Dropdown meldet ihn über onChanged', (
    tester,
  ) async {
    StructuredOutputField? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptStructuredOutputSection(
            fields: const [StructuredOutputField(name: 'wert', description: '')],
            onChanged: (_, updated) => changed = updated,
            onAdd: () {},
            onRemove: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<StructuredFieldType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zahl').last);
    await tester.pumpAndSettle();

    expect(changed?.type, StructuredFieldType.number);
    expect(changed?.name, 'wert');
  });
}
