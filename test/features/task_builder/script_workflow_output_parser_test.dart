import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node_outputs.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_output_types.dart';
import 'package:syscat2/features/task_builder/domain/services/script_workflow_output_parser.dart';

void main() {
  const parser = ScriptWorkflowOutputParser();

  test('erkennt Name und Typ mit beiden Anführungszeichen', () {
    final fields = parser('''
summe = 1
workflow_output("summe", "number", summe)
workflow_output('faellig', 'datetime', heute)
workflow_output( "rechnung" ,"json", {"nr": 1})
''');

    expect(fields, [
      (name: 'summe', type: NodeOutputType.number),
      (name: 'faellig', type: NodeOutputType.datetime),
      (name: 'rechnung', type: NodeOutputType.json),
    ]);
  });

  test('überspringt Kommentare, ungültige Namen, unbekannte Typen und '
      'nicht feste Texte', () {
    final fields = parser('''
# workflow_output("auskommentiert", "string", x)
x = 1  # workflow_output("hinten", "string", x)
workflow_output("2fach", "number", 2)
workflow_output("value", "number", 2)
workflow_output("datum", "date", heute)
workflow_output(name, "string", x)
workflow_output("gültig", "boolean", True)
''');

    expect(fields, [(name: 'gültig', type: NodeOutputType.boolean)]);
  });

  test('bei doppelten Namen gilt der erste Aufruf', () {
    final fields = parser(
      'workflow_output("a", "number", 1)\nworkflow_output("a", "string", "x")',
    );

    expect(fields, [(name: 'a', type: NodeOutputType.number)]);
  });

  test('ein Script hat genau die Werte aus workflow_output, ohne diese '
      'Aufrufe keine', () {
    const flat = ScriptNodeConfig(
      script: 'workflow_output("summe", "number", 42)',
    );
    const plain = ScriptNodeConfig(script: 'output = input');

    expect(hasFlatOutputFields(flat), isTrue);
    expect(outputKeysOf(flat), ['summe']);
    expect(typedFlatOutputFieldsOf(flat), [
      (name: 'summe', type: NodeOutputType.number),
    ]);
    expect(outputKeysOf(plain), isEmpty);
  });
}
