part of 'node_config.dart';

/// Der Laufzeit-Werttyp, den ein Feld einer strukturierten Prompt-Ausgabe
/// vom Modell erwartet — steuert das Genkit-Ausgabeschema
/// (`structuredSchemaFor` im Backend) und damit, ob der resultierende
/// Workflow-Ausgabewert als `NodeOutputValue` vom Typ `number`/`boolean`
/// statt immer `string` ankommt.
enum StructuredFieldType {
  string('Text'),
  number('Zahl'),
  boolean('Wahrheitswert');

  const StructuredFieldType(this.label);

  final String label;
}

class StructuredOutputField extends Equatable {
  const StructuredOutputField({
    required this.name,
    required this.description,
    this.type = StructuredFieldType.string,
  });

  final String name;
  final String description;
  final StructuredFieldType type;

  StructuredOutputField copyWith({
    String? name,
    String? description,
    StructuredFieldType? type,
  }) {
    return StructuredOutputField(
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [name, description, type];
}
