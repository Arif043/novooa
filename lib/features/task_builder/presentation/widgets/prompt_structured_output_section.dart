import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';

class PromptStructuredOutputSection extends StatelessWidget {
  const PromptStructuredOutputSection({
    super.key,
    required this.fields,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<StructuredOutputField> fields;
  final void Function(int index, StructuredOutputField field) onChanged;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Ausgabeformat', style: SyscatTheme.taskBodySmall),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < fields.length; index++)
          _StructuredOutputFieldRow(
            field: fields[index],
            canRemove: fields.length > 1,
            onChanged: (field) => onChanged(index, field),
            onRemove: () => onRemove(index),
          ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: SyscatTheme.primaryOrange),
          label: Text(
            'Feld hinzufügen',
            style: TextStyle(color: SyscatTheme.primaryOrange),
          ),
        ),
      ],
    );
  }
}

class _StructuredOutputFieldRow extends StatefulWidget {
  const _StructuredOutputFieldRow({
    required this.field,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final StructuredOutputField field;
  final bool canRemove;
  final ValueChanged<StructuredOutputField> onChanged;
  final VoidCallback onRemove;

  @override
  State<_StructuredOutputFieldRow> createState() =>
      _StructuredOutputFieldRowState();
}

class _StructuredOutputFieldRowState extends State<_StructuredOutputFieldRow> {
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
  void didUpdateWidget(_StructuredOutputFieldRow oldWidget) {
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
                  decoration: const InputDecoration(hintText: 'Feldname'),
                  onChanged: _emit,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: 'Beschreibung'),
                  onChanged: _emit,
                ),
              ),
              IconButton(
                tooltip: 'Feld entfernen',
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<StructuredFieldType>(
            initialValue: widget.field.type,
            decoration: const InputDecoration(labelText: 'Typ'),
            items: [
              for (final type in StructuredFieldType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) {
              if (type == null) return;
              widget.onChanged(widget.field.copyWith(type: type));
            },
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
