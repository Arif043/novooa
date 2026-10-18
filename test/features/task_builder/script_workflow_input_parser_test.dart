import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/services/script_workflow_input_parser.dart';

void main() {
  test('findet feste Pfade in Reihenfolge, ohne Doppelte und Kommentare', () {
    const script = '''
rechnung = workflow_input("rechnung")
summe = workflow_input('rechnung.summe') + workflow_input("rechnung")
# workflow_input("auskommentiert")
erste = workflow_input("positionen.0")
name = workflow_input(variable)
kaputt = workflow_input("1falsch")
''';

    expect(const ScriptWorkflowInputParser()(script), [
      'rechnung',
      'rechnung.summe',
      'positionen.0',
    ]);
  });
}
