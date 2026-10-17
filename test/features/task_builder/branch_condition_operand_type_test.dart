import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operand_type.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operators.dart';

// Deckt `operandTypeHintFor` ab — die reine, unit-testbare
// Typ-Erkennung für Operanden im Branch-Bedingungs-Baukasten. Jeder in der
// Recherche/Diskussion festgelegte Fall wird einzeln geprüft.
void main() {
  test(
    'isolierter Verweis auf ein strukturiertes number-Feld liefert NumberTypeHint',
    () {
      final graph = _graphWith(_structuredPromptNode());

      final hint = operandTypeHintFor('{{summe}}', graph);

      expect(hint, isA<NumberTypeHint>());
      expect(operatorsFor(hint), [
        ComparisonOperator.equals,
        ComparisonOperator.notEquals,
        ComparisonOperator.greaterThan,
        ComparisonOperator.greaterThanOrEqual,
        ComparisonOperator.lessThan,
        ComparisonOperator.lessThanOrEqual,
      ]);
    },
  );

  test(
    'isolierter Verweis auf ein strukturiertes boolean-Feld liefert BooleanTypeHint',
    () {
      final graph = _graphWith(_structuredPromptNode());

      final hint = operandTypeHintFor('{{bezahlt}}', graph);

      expect(hint, isA<BooleanTypeHint>());
      expect(operatorsFor(hint), [
        ComparisonOperator.isTrue,
        ComparisonOperator.isFalse,
      ]);
    },
  );

  test(
    'isolierter Verweis auf ein strukturiertes string-Feld liefert StringTypeHint',
    () {
      final graph = _graphWith(_structuredPromptNode());

      final hint = operandTypeHintFor('{{titel}}', graph);

      expect(hint, isA<StringTypeHint>());
      expect(operatorsFor(hint), [
        ComparisonOperator.equals,
        ComparisonOperator.notEquals,
        ComparisonOperator.contains,
        ComparisonOperator.notContains,
        ComparisonOperator.startsWith,
        ComparisonOperator.endsWith,
        ComparisonOperator.isEmpty,
        ComparisonOperator.isNotEmpty,
      ]);
    },
  );

  test(
    'isolierter Verweis auf einen Entscheidungs-Prompt liefert EnumTypeHint mit '
    'seinen choices und den Operatoren "ist" und "ist nicht"',
    () {
      final graph = _graphWith(_decisionPromptNode());

      final hint = operandTypeHintFor('{{entscheidung}}', graph);

      expect(hint, isA<EnumTypeHint>());
      expect((hint as EnumTypeHint).values, ['Ja', 'Nein', 'Vielleicht']);
      expect(operatorsFor(hint), [
        ComparisonOperator.equals,
        ComparisonOperator.notEquals,
      ]);
    },
  );

  test(
    'Dialogeingabe-Feld vom Typ Auswahl liefert EnumTypeHint mit seinen options',
    () {
      final graph = _graphWith(_dialogInputNode());

      final hint = operandTypeHintFor('{{kanal}}', graph);

      expect(hint, isA<EnumTypeHint>());
      expect((hint as EnumTypeHint).values, ['E-Mail', 'SMS']);
    },
  );

  test('Dialogeingabe-Feld vom Typ Zahl liefert NumberTypeHint', () {
    final graph = _graphWith(_dialogInputNode());

    final hint = operandTypeHintFor('{{alter}}', graph);

    expect(hint, isA<NumberTypeHint>());
  });

  test('Literal-Zahl ohne {{}} wird ad-hoc als NumberTypeHint erkannt', () {
    final hint = operandTypeHintFor('42', WorkflowGraph.empty());

    expect(hint, isA<NumberTypeHint>());
  });

  test('Literal-Boolean ohne {{}} wird ad-hoc als BooleanTypeHint erkannt', () {
    final hint = operandTypeHintFor('true', WorkflowGraph.empty());

    expect(hint, isA<BooleanTypeHint>());
  });

  test('beliebiger Text ohne {{}} wird als StringTypeHint erkannt', () {
    final hint = operandTypeHintFor('Hallo Welt', WorkflowGraph.empty());

    expect(hint, isA<StringTypeHint>());
  });

  test('ein Pfad in den JSON-Inhalt eines Werts liefert UnknownTypeHint '
      'mit den allgemeinen Operatoren', () {
    final graph = _graphWith(
      const WorkflowNode(
        id: NodeId('text.1'),
        title: 'Text',
        description: '',
        outputs: [WorkflowOutput.primary('freitext')],
        config: StringInputNodeConfig(value: ''),
      ),
    );

    final hint = operandTypeHintFor('{{freitext.name}}', graph);

    expect(hint, isA<UnknownTypeHint>());
    expect(operatorsFor(hint), [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
      ComparisonOperator.greaterThan,
      ComparisonOperator.greaterThanOrEqual,
      ComparisonOperator.lessThan,
      ComparisonOperator.lessThanOrEqual,
      ComparisonOperator.contains,
    ]);
  });

  test('gemischter Text mit eingebettetem Ausdruck (nicht isoliert) wird wie '
      'ein Literal behandelt (StringTypeHint), da der Rohwert des '
      'eingebetteten Ausdrucks zur Bauzeit nicht erhalten bleibt', () {
    final graph = _graphWith(_structuredPromptNode());

    final hint = operandTypeHintFor('Summe: {{summe}} Euro', graph);

    expect(hint, isA<StringTypeHint>());
  });

  test('ein leerer Operand liefert UnknownTypeHint', () {
    final hint = operandTypeHintFor('', WorkflowGraph.empty());

    expect(hint, isA<UnknownTypeHint>());
  });
}

WorkflowGraph _graphWith(WorkflowNode node) {
  return WorkflowGraph(nodes: [node], edges: const []);
}

WorkflowNode _structuredPromptNode() {
  return const WorkflowNode(
    id: NodeId('prompt.1'),
    title: 'Prompt',
    description: '',
    outputs: [
      WorkflowOutput(key: 'titel', name: 'titel', showOnCanvas: true),
      WorkflowOutput(key: 'summe', name: 'summe', showOnCanvas: true),
      WorkflowOutput(key: 'bezahlt', name: 'bezahlt', showOnCanvas: true),
    ],
    config: PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.structured,
      choices: [],
      structuredFields: [
        StructuredOutputField(name: 'titel', description: ''),
        StructuredOutputField(
          name: 'summe',
          description: '',
          type: StructuredFieldType.number,
        ),
        StructuredOutputField(
          name: 'bezahlt',
          description: '',
          type: StructuredFieldType.boolean,
        ),
      ],
    ),
  );
}

WorkflowNode _decisionPromptNode() {
  return const WorkflowNode(
    id: NodeId('prompt.2'),
    title: 'Prompt',
    description: '',
    outputs: [WorkflowOutput.primary('entscheidung')],
    config: PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.decision,
      choices: ['Ja', 'Nein', 'Vielleicht'],
    ),
  );
}

WorkflowNode _dialogInputNode() {
  return const WorkflowNode(
    id: NodeId('dialog.1'),
    title: 'Dialogeingabe',
    description: '',
    outputs: [
      WorkflowOutput(key: 'alter', name: 'alter', showOnCanvas: true),
      WorkflowOutput(key: 'kanal', name: 'kanal', showOnCanvas: true),
    ],
    config: DialogInputNodeConfig(
      instruction: '',
      fields: [
        DialogInputField(name: 'alter', type: DialogInputFieldType.integer),
        DialogInputField(
          name: 'kanal',
          type: DialogInputFieldType.selection,
          options: ['E-Mail', 'SMS'],
        ),
      ],
    ),
  );
}
