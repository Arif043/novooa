import 'package:flutter/material.dart';

import '../../domain/entities/task_run_dialog_input_field.dart';
import 'task_run_dialog_input_radio.dart';

class TaskRunDialogInputFieldControl extends StatelessWidget {
  const TaskRunDialogInputFieldControl({
    super.key,
    required this.field,
    required this.controller,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final TextEditingController? controller;
  final Object? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return switch (field.type) {
      TaskRunDialogInputFieldType.string => _TextInput(
        field: field,
        controller: controller!,
      ),
      TaskRunDialogInputFieldType.number ||
      TaskRunDialogInputFieldType.integer ||
      TaskRunDialogInputFieldType.decimal => _NumberInput(
        field: field,
        controller: controller!,
      ),
      TaskRunDialogInputFieldType.selection => _SelectionInput(
        field: field,
        value: value as String?,
        onValueChanged: onValueChanged,
      ),
      TaskRunDialogInputFieldType.boolean => _BooleanInput(
        field: field,
        value: value as bool? ?? false,
        onValueChanged: onValueChanged,
      ),
      TaskRunDialogInputFieldType.radio => TaskRunDialogInputRadio(
        field: field,
        value: value as String?,
        onValueChanged: onValueChanged,
      ),
    };
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.field, required this.controller});

  final TaskRunDialogInputField field;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(labelText: field.name),
      validator: _requiredText,
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({required this.field, required this.controller});

  final TaskRunDialogInputField field;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: field.name),
      validator: (value) => _numberError(field.type, value),
    );
  }
}

class _SelectionInput extends StatelessWidget {
  const _SelectionInput({
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final String? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: field.name),
      items: [
        for (final option in optionsForDialogInput(field))
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      validator: _requiredChoice,
      onChanged: (selected) => onValueChanged(field.name, selected),
    );
  }
}

class _BooleanInput extends StatelessWidget {
  const _BooleanInput({
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final bool value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(field.name),
      onChanged: (selected) => onValueChanged(field.name, selected ?? false),
    );
  }
}

List<String> optionsForDialogInput(TaskRunDialogInputField field) {
  return field.options.where((option) => option.trim().isNotEmpty).toList();
}

String? _requiredText(String? value) {
  return value == null || value.trim().isEmpty ? 'Bitte ausfüllen.' : null;
}

String? _requiredChoice(String? value) {
  return value == null || value.isEmpty ? 'Bitte auswählen.' : null;
}

String? _numberError(TaskRunDialogInputFieldType type, String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Bitte ausfüllen.';
  if (type == TaskRunDialogInputFieldType.integer) {
    return int.tryParse(raw) == null ? 'Bitte eine ganze Zahl eingeben.' : null;
  }
  return double.tryParse(raw) == null ? 'Bitte eine Zahl eingeben.' : null;
}
