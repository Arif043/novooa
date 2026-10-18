import 'package:flutter/services.dart';

/// Der Script-Aufruf für einen gewählten Workflow-Wert: aus `{{rechnung.summe}}`
/// wird `workflow_input("rechnung.summe")`.
String workflowInputCallFor(String expression) {
  final path = expression.replaceAll(RegExp(r'^\{\{\s*|\s*\}\}$'), '');
  return 'workflow_input("$path")';
}

/// Setzt [text] an die Cursorposition (oder ersetzt die Auswahl); ohne gültige
/// Auswahl ans Ende. Der Cursor steht danach hinter dem eingefügten Text.
TextEditingValue insertAtSelection(TextEditingValue value, String text) {
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  final updated = value.text.replaceRange(selection.start, selection.end, text);
  return TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(offset: selection.start + text.length),
  );
}
