import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

// Deckt `StructuredOutputField.type` ab: neu hinzugefügtes Feld, das
// `structuredSchemaFor` im Backend steuert (string/number/boolean statt
// immer nur string). Optional mit Default `StructuredFieldType.string`,
// damit bestehende Konstruktionsaufrufe unverändert bleiben.
void main() {
  test('StructuredOutputField ist ohne expliziten Typ standardmäßig string', () {
    const field = StructuredOutputField(name: 'titel', description: '');

    expect(field.type, StructuredFieldType.string);
  });

  test('copyWith ändert nur den Typ und lässt Name/Beschreibung unangetastet', () {
    const field = StructuredOutputField(name: 'summe', description: 'in Euro');

    final updated = field.copyWith(type: StructuredFieldType.number);

    expect(updated.name, 'summe');
    expect(updated.description, 'in Euro');
    expect(updated.type, StructuredFieldType.number);
  });

  test('copyWith ohne Argumente behält den bestehenden Typ bei', () {
    const field = StructuredOutputField(
      name: 'aktiv',
      description: '',
      type: StructuredFieldType.boolean,
    );

    final updated = field.copyWith(description: 'Ist der Vertrag aktiv?');

    expect(updated.type, StructuredFieldType.boolean);
  });

  test('zwei Felder mit unterschiedlichem Typ sind nicht gleich (Equatable)', () {
    const asString = StructuredOutputField(name: 'wert', description: '');
    const asNumber = StructuredOutputField(
      name: 'wert',
      description: '',
      type: StructuredFieldType.number,
    );

    expect(asString, isNot(asNumber));
  });
}
