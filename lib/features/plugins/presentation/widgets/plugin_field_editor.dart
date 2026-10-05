import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/plugin_manifest.dart';

/// Rendert ein vom Plugin beschriebenes Feld. Der Wert ist `String`, `num` oder
/// `bool`, je nach [PluginField.kind]; leere Zahleneingaben melden `0`.
class PluginFieldEditor extends StatefulWidget {
  const PluginFieldEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.secretIsSet = false,
  });

  final PluginField field;
  final Object? value;
  final ValueChanged<Object> onChanged;

  /// Für Geheimnisse: im Backend ist bereits ein Wert gespeichert.
  final bool secretIsSet;

  @override
  State<PluginFieldEditor> createState() => _PluginFieldEditorState();
}

class _PluginFieldEditorState extends State<PluginFieldEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: _initialText(),
  );

  String _initialText() {
    if (widget.field.secret) return '';
    final value = widget.value ?? widget.field.defaultValue;
    return value == null ? '' : '$value';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final label = field.required ? '${field.label} *' : field.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: switch (field.kind) {
        PluginFieldKind.toggle => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: field.description == null ? null : Text(field.description!),
          value: (widget.value ?? field.defaultValue) == true,
          onChanged: widget.onChanged,
        ),
        PluginFieldKind.choice => DropdownButtonFormField<String>(
          initialValue: _selectedOption(),
          decoration: _decoration(label),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: (value) {
            if (value != null) widget.onChanged(value);
          },
        ),
        PluginFieldKind.number => TextField(
          controller: _controller,
          decoration: _decoration(label),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: (text) =>
              widget.onChanged(num.tryParse(text.replaceAll(',', '.')) ?? 0),
        ),
        _ => TextField(
          controller: _controller,
          decoration: _decoration(label),
          obscureText: field.secret,
          minLines: field.kind == PluginFieldKind.multilineText ? 3 : 1,
          maxLines: field.kind == PluginFieldKind.multilineText ? 8 : 1,
          onChanged: widget.onChanged,
        ),
      },
    );
  }

  String? _selectedOption() {
    final current = (widget.value ?? widget.field.defaultValue)?.toString();
    return widget.field.options.any((option) => option.value == current)
        ? current
        : null;
  }

  InputDecoration _decoration(String label) {
    final field = widget.field;
    return InputDecoration(
      labelText: label,
      helperText: field.description,
      hintText: field.secret && widget.secretIsSet
          ? 'Gesetzt – leer lassen, um ihn zu behalten'
          : field.kind == PluginFieldKind.template
          ? 'z. B. {{rechnung.summe}}'
          : null,
      border: const OutlineInputBorder(),
    );
  }
}
