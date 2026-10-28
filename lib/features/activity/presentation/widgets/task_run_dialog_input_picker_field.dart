import 'package:flutter/material.dart';

/// Ein Formularfeld, dessen Wert aus einem Auswahldialog kommt (Datum,
/// Uhrzeit): sieht aus wie ein Textfeld, ist aber nicht tippbar, damit kein
/// ungültiges Format entsteht.
class TaskRunDialogInputPickerField extends StatelessWidget {
  const TaskRunDialogInputPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.displayTextFor,
    required this.icon,
    required this.pickLabel,
    required this.missingValueMessage,
    required this.onPick,
  });

  final String label;
  final String? value;

  /// Lesbare Form eines Werts im Wire-Format; `null`, wenn keiner gewählt ist.
  final String? Function(String? value) displayTextFor;
  final IconData icon;
  final String pickLabel;
  final String missingValueMessage;

  /// Öffnet die Auswahl beim aktuellen Wert; liefert den neuen Wert im
  /// Wire-Format oder `null` bei Abbruch.
  final Future<String?> Function(String? current) onPick;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: (current) => current == null ? missingValueMessage : null,
      builder: (state) => _buildField(context, state),
    );
  }

  Widget _buildField(BuildContext context, FormFieldState<String> state) {
    final displayText = displayTextFor(state.value);
    return Semantics(
      button: true,
      label: '$label, $pickLabel',
      value: displayText,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _pick(state),
        borderRadius: _inputRadius(context),
        child: InputDecorator(
          isEmpty: displayText == null,
          decoration: InputDecoration(
            labelText: label,
            hintText: pickLabel,
            errorText: state.errorText,
            suffixIcon: Icon(icon),
          ),
          child: Text(displayText ?? ''),
        ),
      ),
    );
  }

  /// Gleiche Ecken wie die Textfelder, damit die Welle nicht übersteht.
  BorderRadius _inputRadius(BuildContext context) {
    final border = Theme.of(context).inputDecorationTheme.border;
    return border is OutlineInputBorder
        ? border.borderRadius
        : BorderRadius.zero;
  }

  Future<void> _pick(FormFieldState<String> state) async {
    final selected = await onPick(state.value);
    if (selected != null) state.didChange(selected);
  }
}
