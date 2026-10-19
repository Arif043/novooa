import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import 'structured_field_labels.dart';

/// Ein Feld des Ergebnisses: Name, Beschreibung, Typ und bei Dateien das Format.
class StructuredOutputFieldRow extends StatefulWidget {
  const StructuredOutputFieldRow({
    super.key,
    required this.field,
    required this.allowedTypes,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final StructuredOutputField field;
  final List<StructuredFieldType> allowedTypes;
  final bool canRemove;
  final ValueChanged<StructuredOutputField> onChanged;
  final VoidCallback onRemove;

  @override
  State<StructuredOutputFieldRow> createState() =>
      _StructuredOutputFieldRowState();
}

class _StructuredOutputFieldRowState extends State<StructuredOutputFieldRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field.name);
    _descriptionController = TextEditingController(
      text: widget.field.description,
    );
  }

  @override
  void didUpdateWidget(StructuredOutputFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_nameController, widget.field.name);
    _sync(_descriptionController, widget.field.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.ui_feldname.tr(),
                  ),
                  onChanged: _emit,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.ui_beschreibung.tr(),
                  ),
                  onChanged: _emit,
                ),
              ),
              IconButton(
                tooltip: LocaleKeys.ui_feld_entfernen.tr(),
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _TypeAndFormat(
            field: widget.field,
            allowedTypes: widget.allowedTypes,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }

  void _emit(String _) {
    widget.onChanged(
      widget.field.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
      ),
    );
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _TypeAndFormat extends StatelessWidget {
  const _TypeAndFormat({
    required this.field,
    required this.allowedTypes,
    required this.onChanged,
  });

  final StructuredOutputField field;
  final List<StructuredFieldType> allowedTypes;
  final ValueChanged<StructuredOutputField> onChanged;

  @override
  Widget build(BuildContext context) {
    final isFile = field.type == StructuredFieldType.file;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<StructuredFieldType>(
            initialValue: field.type,
            isExpanded: true,
            decoration: InputDecoration(labelText: LocaleKeys.ui_typ.tr()),
            items: [
              for (final type in {...allowedTypes, field.type})
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) {
              if (type != null) onChanged(field.copyWith(type: type));
            },
          ),
        ),
        if (isFile) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonFormField<OutputFileFormat>(
              initialValue: field.fileFormat,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_file_format.tr(),
              ),
              items: [
                for (final format in OutputFileFormat.values)
                  DropdownMenuItem(value: format, child: Text(format.label)),
              ],
              onChanged: (format) {
                if (format != null) {
                  onChanged(field.copyWith(fileFormat: format));
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
