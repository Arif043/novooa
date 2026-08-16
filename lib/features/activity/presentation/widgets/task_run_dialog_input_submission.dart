import 'package:flutter/material.dart';

import '../../domain/entities/task_run_dialog_input_field.dart';

void initializeDialogInput(
  List<TaskRunDialogInputField> fields,
  Map<String, TextEditingController> controllers,
  Map<String, Object?> values,
) {
  for (final field in fields) {
    if (usesDialogTextInput(field.type)) {
      controllers[field.name] = TextEditingController();
    } else if (field.type == TaskRunDialogInputFieldType.boolean) {
      values[field.name] = false;
    }
  }
}

Map<String, Object?> dialogInputSubmissionValues(
  List<TaskRunDialogInputField> fields,
  Map<String, TextEditingController> controllers,
  Map<String, Object?> values,
) {
  return {
    for (final field in fields)
      field.name: dialogInputValueFor(field, controllers, values),
  };
}

Object? dialogInputValueFor(
  TaskRunDialogInputField field,
  Map<String, TextEditingController> controllers,
  Map<String, Object?> values,
) {
  if (field.type == TaskRunDialogInputFieldType.boolean ||
      !usesDialogTextInput(field.type)) {
    return values[field.name];
  }
  final value = controllers[field.name]!.text.trim();
  if (field.type == TaskRunDialogInputFieldType.integer) {
    return int.tryParse(value);
  }
  if (field.type == TaskRunDialogInputFieldType.number ||
      field.type == TaskRunDialogInputFieldType.decimal) {
    return double.tryParse(value);
  }
  return value;
}

bool usesDialogTextInput(TaskRunDialogInputFieldType type) {
  return type == TaskRunDialogInputFieldType.string ||
      type == TaskRunDialogInputFieldType.number ||
      type == TaskRunDialogInputFieldType.integer ||
      type == TaskRunDialogInputFieldType.decimal;
}
