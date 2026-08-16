import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';

class DialogInputFieldEditor extends StatelessWidget {
  const DialogInputFieldEditor({
    super.key,
    required this.field,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final DialogInputField field;
  final bool canRemove;
  final ValueChanged<DialogInputField> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _NameField(field: field, onChanged: onChanged),
                ),
                const SizedBox(width: AppSpacing.sm),
                _RemoveFieldButton(enabled: canRemove, onRemove: onRemove),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TypeField(field: field, onChanged: onChanged),
            if (field.type.needsOptions) ...[
              const SizedBox(height: AppSpacing.sm),
              _OptionsEditor(field: field, onChanged: onChanged),
            ],
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.field, required this.onChanged});

  final DialogInputField field;
  final ValueChanged<DialogInputField> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: field.name,
      decoration: const InputDecoration(labelText: 'Feldname'),
      onChanged: (name) => onChanged(field.copyWith(name: name)),
    );
  }
}

class _TypeField extends StatelessWidget {
  const _TypeField({required this.field, required this.onChanged});

  final DialogInputField field;
  final ValueChanged<DialogInputField> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DialogInputFieldType>(
      initialValue: field.type,
      decoration: const InputDecoration(labelText: 'Datentyp'),
      items: [
        for (final type in DialogInputFieldType.values)
          DropdownMenuItem(value: type, child: Text(type.label)),
      ],
      onChanged: (type) {
        if (type == null) return;
        final options = type.needsOptions
            ? (field.options.isEmpty ? const [''] : field.options)
            : const <String>[];
        onChanged(field.copyWith(type: type, options: options));
      },
    );
  }
}

class _OptionsEditor extends StatelessWidget {
  const _OptionsEditor({required this.field, required this.onChanged});

  final DialogInputField field;
  final ValueChanged<DialogInputField> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optionen', style: Theme.of(context).textTheme.labelLarge),
        for (var index = 0; index < field.options.length; index++)
          _OptionField(
            value: field.options[index],
            canRemove: field.options.length > 1,
            onChanged: (value) => onChanged(field.updateOption(index, value)),
            onRemove: () => onChanged(field.removeOption(index)),
          ),
        IconButton(
          tooltip: 'Option hinzufügen',
          onPressed: () => onChanged(field.addOption()),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.value,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final String value;
  final bool canRemove;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: value,
            decoration: const InputDecoration(labelText: 'Option'),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          tooltip: 'Option entfernen',
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }
}

class _RemoveFieldButton extends StatelessWidget {
  const _RemoveFieldButton({required this.enabled, required this.onRemove});

  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Feld entfernen',
      onPressed: enabled ? onRemove : null,
      icon: const Icon(Icons.delete_outline),
    );
  }
}
