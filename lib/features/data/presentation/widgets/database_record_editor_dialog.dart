import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_record.dart';

class DatabaseRecordEditorDialog extends StatefulWidget {
  const DatabaseRecordEditorDialog({this.record, super.key});

  final DataRecord? record;

  @override
  State<DatabaseRecordEditorDialog> createState() =>
      _DatabaseRecordEditorDialogState();
}

class _DatabaseRecordEditorDialogState
    extends State<DatabaseRecordEditorDialog> {
  late List<_EditableField> _fields;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields = [
      for (final entry
          in widget.record?.fields.entries ??
              const Iterable<MapEntry<String, Object?>>.empty())
        _EditableField(
          entry.key,
          entry.value is Map || entry.value is List
              ? jsonEncode(entry.value)
              : '${entry.value ?? ''}',
          isJson: entry.value is Map || entry.value is List,
        ),
    ];
    if (_fields.isEmpty) _fields = [_EditableField('', '')];
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.record == null ? 'Datensatz anlegen' : 'Datensatz bearbeiten',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ..._fields.indexed.map(
                (entry) => _EditableRow(
                  field: entry.$2,
                  canRemove: _fields.length > 1,
                  onRemove: () => _remove(entry.$1),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Feld hinzufügen'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }

  void _add() => setState(() => _fields.add(_EditableField('', '')));

  void _remove(int index) => setState(() {
    _fields.removeAt(index).dispose();
  });

  void _save() {
    final entries = <String, Object?>{};
    try {
      for (final field in _fields) {
        final name = field.name.text.trim();
        if (!_isFieldName(name))
          throw const FormatException(
            'Feldnamen beginnen mit einem Buchstaben oder Unterstrich.',
          );
        if (entries.containsKey(name)) {
          throw const FormatException(
            'Jeder Feldname darf nur einmal vorkommen.',
          );
        }
        entries[name] = _valueFrom(field);
      }
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    Navigator.pop(context, entries);
  }

  bool _isFieldName(String value) =>
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]{0,63}$').hasMatch(value);

  Object? _valueFrom(_EditableField field) {
    if (field.isJson) {
      try {
        return jsonDecode(field.value.text);
      } on FormatException {
        throw const FormatException(
          'Strukturierte Werte müssen gültiges JSON sein.',
        );
      }
    }
    final trimmed = field.value.text.trim();
    if (trimmed == 'true') {
      return true;
    }
    if (trimmed == 'false') {
      return false;
    }
    return num.tryParse(trimmed) ?? field.value.text;
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.field,
    required this.canRemove,
    required this.onRemove,
  });

  final _EditableField field;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: field.name,
              decoration: const InputDecoration(labelText: 'Feld'),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: field.value,
              maxLines: field.isJson ? 3 : 1,
              decoration: InputDecoration(
                labelText: field.isJson ? 'JSON-Wert' : 'Wert',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Feld entfernen',
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _EditableField {
  _EditableField(String name, String value, {this.isJson = false})
    : name = TextEditingController(text: name),
      value = TextEditingController(text: value);

  final TextEditingController name;
  final TextEditingController value;
  final bool isJson;

  void dispose() {
    name.dispose();
    value.dispose();
  }
}
