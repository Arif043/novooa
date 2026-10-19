import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import 'structured_output_field_row.dart';

/// Die Felder eines strukturierten Ergebnisses (Prompt, Teamarbeit): Name,
/// Beschreibung und Typ, bei Dateien zusätzlich das Format. [allowedTypes]
/// legt fest, welche Typen der Baustein liefern kann.
class StructuredOutputFieldsEditor extends StatelessWidget {
  const StructuredOutputFieldsEditor({
    super.key,
    required this.fields,
    required this.allowedTypes,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<StructuredOutputField> fields;
  final List<StructuredFieldType> allowedTypes;
  final void Function(int index, StructuredOutputField field) onChanged;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          LocaleKeys.ui_ausgabeformat.tr(),
          style: SyscatTheme.taskBodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < fields.length; index++)
          StructuredOutputFieldRow(
            field: fields[index],
            allowedTypes: allowedTypes,
            canRemove: fields.length > 1,
            onChanged: (field) => onChanged(index, field),
            onRemove: () => onRemove(index),
          ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: SyscatTheme.primaryOrange),
          label: Text(
            LocaleKeys.ui_feld_hinzufuegen.tr(),
            style: TextStyle(color: SyscatTheme.primaryOrange),
          ),
        ),
      ],
    );
  }
}
