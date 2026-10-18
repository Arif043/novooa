import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_input_warning.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_workflow_input_insertion.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';

void main() {
  test('aus einem gewählten Wert wird ein workflow_input-Aufruf', () {
    expect(
      workflowInputCallFor('{{rechnung.summe}}'),
      'workflow_input("rechnung.summe")',
    );
  });

  test('fügt an der Cursorposition ein und setzt den Cursor dahinter', () {
    const value = TextEditingValue(
      text: 'summe = \nprint(summe)',
      selection: TextSelection.collapsed(offset: 8),
    );

    final updated = insertAtSelection(value, 'workflow_input("summe")');

    expect(updated.text, 'summe = workflow_input("summe")\nprint(summe)');
    expect(updated.selection.baseOffset, 31);
  });

  test('ohne gültige Auswahl wird ans Ende angehängt', () {
    final updated = insertAtSelection(
      const TextEditingValue(text: 'x = '),
      'workflow_input("a")',
    );

    expect(updated.text, 'x = workflow_input("a")');
  });

  test('meldet gelesene Werte, die es vor dem Baustein nicht gibt', () {
    const suggestions = [
      TemplateExpressionSuggestion(
        expression: '{{rechnung}}',
        label: 'Rechnung',
      ),
    ];
    const script = '''
summe = workflow_input("rechnung.summe")
kunde = workflow_input("kunde")
element = workflow_input("iteration.value")
''';

    expect(unknownScriptInputs(script, suggestions), ['kunde']);
  });
}
