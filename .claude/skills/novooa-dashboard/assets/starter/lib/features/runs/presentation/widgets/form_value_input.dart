import 'package:flutter/material.dart';

import '../../domain/entities/task_run.dart';

/// Ein Feld des Formulars, passend zu seinem Typ. Meldet `null`, solange der
/// Wert fehlt oder ungültig ist.
class FormValueInput extends StatelessWidget {
  const FormValueInput({
    super.key,
    required this.field,
    required this.onChanged,
  });

  final FormFieldSpec field;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) => switch (field.type) {
    FormFieldType.boolean => _BooleanInput(field: field, onChanged: onChanged),
    FormFieldType.selection ||
    FormFieldType.radio => _ChoiceInput(field: field, onChanged: onChanged),
    _ => _TextInput(field: field, onChanged: onChanged),
  };
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.field, required this.onChanged});

  final FormFieldSpec field;
  final ValueChanged<Object?> onChanged;

  Object? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return switch (field.type) {
      FormFieldType.integer => int.tryParse(trimmed),
      FormFieldType.number ||
      FormFieldType.decimal => num.tryParse(trimmed.replaceAll(',', '.')),
      _ => trimmed,
    };
  }

  @override
  Widget build(BuildContext context) => TextField(
    keyboardType: field.isNumeric
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : TextInputType.text,
    decoration: InputDecoration(labelText: field.name),
    onChanged: (text) => onChanged(_parse(text)),
  );
}

class _ChoiceInput extends StatelessWidget {
  const _ChoiceInput({required this.field, required this.onChanged});

  final FormFieldSpec field;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    isExpanded: true,
    decoration: InputDecoration(labelText: field.name),
    items: [
      for (final option in field.options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    onChanged: onChanged,
  );
}

class _BooleanInput extends StatefulWidget {
  const _BooleanInput({required this.field, required this.onChanged});

  final FormFieldSpec field;
  final ValueChanged<Object?> onChanged;

  @override
  State<_BooleanInput> createState() => _BooleanInputState();
}

class _BooleanInputState extends State<_BooleanInput> {
  var _value = false;

  @override
  void initState() {
    super.initState();
    // Ein Schalter hat immer einen Wert; „aus“ ist eine gültige Antwort.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onChanged(false),
    );
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(widget.field.name),
    value: _value,
    onChanged: (value) {
      setState(() => _value = value);
      widget.onChanged(value);
    },
  );
}
