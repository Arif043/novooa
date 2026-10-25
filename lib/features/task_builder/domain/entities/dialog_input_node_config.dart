part of 'node_config.dart';

enum DialogInputFieldType {
  string('Text'),
  number('Zahl'),
  integer('Ganze Zahl'),
  decimal('Fließkommazahl'),
  selection('Auswahl'),
  boolean('Schalter'),
  radio('Radio-Buttons'),
  image('Bild');

  const DialogInputFieldType(this.label);

  final String label;

  bool get needsOptions {
    return this == DialogInputFieldType.selection ||
        this == DialogInputFieldType.radio;
  }
}

class DialogInputField extends Equatable {
  const DialogInputField({
    required this.name,
    required this.type,
    this.options = const [],
  });

  final String name;
  final DialogInputFieldType type;
  final List<String> options;

  DialogInputField copyWith({
    String? name,
    DialogInputFieldType? type,
    List<String>? options,
  }) {
    return DialogInputField(
      name: name ?? this.name,
      type: type ?? this.type,
      options: options ?? this.options,
    );
  }

  DialogInputField updateOption(int index, String value) {
    if (index < 0 || index >= options.length) return this;
    final updatedOptions = [...options]..[index] = value;
    return copyWith(options: updatedOptions);
  }

  DialogInputField addOption() => copyWith(options: [...options, '']);

  DialogInputField removeOption(int index) {
    if (index < 0 || index >= options.length || options.length <= 1) {
      return this;
    }
    final updatedOptions = [...options]..removeAt(index);
    return copyWith(options: updatedOptions);
  }

  @override
  List<Object?> get props => [name, type, options];
}

class DialogInputNodeConfig extends NodeConfig {
  const DialogInputNodeConfig({
    required this.instruction,
    required this.fields,
  });

  final String instruction;
  final List<DialogInputField> fields;

  factory DialogInputNodeConfig.initial() {
    return const DialogInputNodeConfig(
      instruction: 'Bitte fülle das Formular aus.',
      fields: [
        DialogInputField(name: 'Antwort', type: DialogInputFieldType.string),
      ],
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.dialogInput;

  @override
  List<Object?> get props => [instruction, fields];

  DialogInputNodeConfig copyWith({
    String? instruction,
    List<DialogInputField>? fields,
  }) {
    return DialogInputNodeConfig(
      instruction: instruction ?? this.instruction,
      fields: fields ?? this.fields,
    );
  }

  DialogInputNodeConfig updateField(int index, DialogInputField field) {
    if (index < 0 || index >= fields.length) return this;
    final updatedFields = [...fields]..[index] = field;
    return copyWith(fields: updatedFields);
  }

  DialogInputNodeConfig addField() {
    return copyWith(
      fields: [
        ...fields,
        const DialogInputField(name: '', type: DialogInputFieldType.string),
      ],
    );
  }

  DialogInputNodeConfig removeField(int index) {
    if (index < 0 || index >= fields.length || fields.length <= 1) {
      return this;
    }
    final updatedFields = [...fields]..removeAt(index);
    return copyWith(fields: updatedFields);
  }
}
