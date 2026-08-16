import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import 'task_run_dialog_input_field_control.dart';

class TaskRunDialogInputRadio extends StatelessWidget {
  const TaskRunDialogInputRadio({
    super.key,
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final String? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: _requiredChoice,
      builder: (state) => RadioGroup<String>(
        groupValue: value,
        onChanged: (selected) {
          state.didChange(selected);
          onValueChanged(field.name, selected);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.name, style: Theme.of(context).textTheme.labelLarge),
            for (final option in optionsForDialogInput(field))
              RadioListTile<String>(
                value: option,
                contentPadding: EdgeInsets.zero,
                title: Text(option),
              ),
            if (state.hasError) _ErrorText(text: state.errorText!),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

String? _requiredChoice(String? value) {
  return value == null || value.isEmpty ? 'Bitte auswählen.' : null;
}
