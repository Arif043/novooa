import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/structured_field_labels.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/structured_output_fields_editor.dart';

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
          body: StructuredOutputFieldsEditor(
            allowedTypes: promptFieldTypes,
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

  testWidgets('Bearbeiten des Namens behält den zuvor gewählten Typ bei '
      '(Regression: _emit setzte den Typ zuvor still auf string zurück)', (
    tester,
  ) async {
    StructuredOutputField? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StructuredOutputFieldsEditor(
            allowedTypes: promptFieldTypes,
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
  });

  testWidgets(
    'Auswahl eines neuen Typs im Dropdown meldet ihn über onChanged',
    (tester) async {
      StructuredOutputField? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StructuredOutputFieldsEditor(
              allowedTypes: promptFieldTypes,
              fields: const [
                StructuredOutputField(name: 'wert', description: ''),
              ],
              onChanged: (_, updated) => changed = updated,
              onAdd: () {},
              onRemove: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<StructuredFieldType>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zahl').last);
      await tester.pumpAndSettle();

      expect(changed?.type, StructuredFieldType.number);
      expect(changed?.name, 'wert');
    },
  );

  testWidgets('der Prompt-Baustein bietet keine Datei an', (tester) async {
    await tester.pumpWidget(_editor(promptFieldTypes, const []));

    await tester.tap(find.byType(DropdownButtonFormField<StructuredFieldType>));
    await tester.pumpAndSettle();

    expect(find.text('Datum und Uhrzeit'), findsWidgets);
    expect(find.text('Datei'), findsNothing);
  });

  testWidgets('ein Datei-Feld zeigt und meldet sein Format', (tester) async {
    final changes = <StructuredOutputField>[];
    await tester.pumpWidget(
      _editor(
        StructuredFieldType.values,
        changes,
        type: StructuredFieldType.file,
      ),
    );

    expect(find.text('Markdown (.md)'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<OutputFileFormat>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tabelle (.csv)').last);
    await tester.pumpAndSettle();

    expect(changes.last.fileFormat, OutputFileFormat.csv);
    expect(changes.last.type, StructuredFieldType.file);
  });
}

Widget _editor(
  List<StructuredFieldType> allowedTypes,
  List<StructuredOutputField> changes, {
  StructuredFieldType type = StructuredFieldType.string,
}) {
  return MaterialApp(
    home: Scaffold(
      body: StructuredOutputFieldsEditor(
        allowedTypes: allowedTypes,
        fields: [
          StructuredOutputField(name: 'bericht', description: '', type: type),
        ],
        onChanged: (_, field) => changes.add(field),
        onAdd: () {},
        onRemove: (_) {},
      ),
    ),
  );
}
