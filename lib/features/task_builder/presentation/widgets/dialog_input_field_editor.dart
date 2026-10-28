import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import 'dialog_input_field_type_label.dart';

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
      decoration: InputDecoration(labelText: LocaleKeys.ui_feldname.tr()),
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
      decoration: InputDecoration(labelText: LocaleKeys.ui_datentyp.tr()),
      items: [
        for (final type in DialogInputFieldType.values)
          DropdownMenuItem(
            value: type,
            child: Text(dialogInputFieldTypeLabel(type)),
          ),
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
        Text(
          LocaleKeys.ui_optionen.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        for (var index = 0; index < field.options.length; index++)
          _OptionField(
            value: field.options[index],
            canRemove: field.options.length > 1,
            onChanged: (value) => onChanged(field.updateOption(index, value)),
            onRemove: () => onChanged(field.removeOption(index)),
          ),
        IconButton(
          tooltip: LocaleKeys.ui_option_hinzufuegen.tr(),
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
            decoration: InputDecoration(labelText: LocaleKeys.ui_option.tr()),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_option_entfernen.tr(),
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
      tooltip: LocaleKeys.ui_feld_entfernen.tr(),
      onPressed: enabled ? onRemove : null,
      icon: const Icon(Icons.delete_outline),
    );
  }
}
