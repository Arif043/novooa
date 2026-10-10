import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';

void main() {
  test('bietet nur Outputs und Script-Variablen aus Vorgängerpfad an', () {
    final graph = WorkflowGraph(
      nodes: [
        _node('eingabe'),
        _scriptNode(),
        _node('ziel'),
        _node('nachfolger'),
        _node('isoliert'),
      ],
      edges: [
        _edge('eingabe', 'script'),
        _edge('script', 'ziel'),
        _edge('ziel', 'nachfolger'),
      ],
    );

    final expressions = templateExpressionSuggestions(
      graph: graph,
      targetNodeId: const NodeId('ziel'),
    );

    expect(expressions.map((suggestion) => suggestion.expression), [
      '{{eingabe}}',
      '{{script}}',
      '{{kunde}}',
      '{{anzahl}}',
    ]);
  });

  test('bietet die weiteren Werte unter ihrem eigenen Namen wie den '
      'Hauptwert an', () {
    final graph = WorkflowGraph(
      nodes: [_saveDocumentNode(), _node('nachfolger')],
      edges: [_edge('speichern', 'nachfolger')],
    );

    final suggestions = templateExpressionSuggestions(
      graph: graph,
      targetNodeId: const NodeId('nachfolger'),
    );

    final expressions = suggestions.map((s) => s.expression);
    expect(
      expressions,
      containsAll(['{{speichern}}', '{{Angelegt}}', '{{Anzahl}}']),
    );
    expect(expressions.where((e) => e.contains('.')), isEmpty);
    expect(
      suggestions.every(
        (s) => s.kind == TemplateExpressionSuggestionKind.primary,
      ),
      isTrue,
    );
  });

  test('strukturierte Prompt-Felder werden direkt angeboten', () {
    final graph = WorkflowGraph(
      nodes: [_structuredPromptNode(), _node('nachfolger')],
      edges: [_edge('prompt', 'nachfolger')],
    );

    final suggestions = templateExpressionSuggestions(
      graph: graph,
      targetNodeId: const NodeId('nachfolger'),
    );

    expect(suggestions.map((s) => s.expression), contains('{{titel}}'));
  });

  test('ein Script mit workflow_output bietet seine Ausgaben flach an statt '
      'seines Text-Outputs', () {
    final graph = WorkflowGraph(
      nodes: [
        const WorkflowNode(
          id: NodeId('script'),
          title: 'Berechnung',
          description: '',
          outputName: 'script',
          config: ScriptNodeConfig(
            script: 'workflow_output("summe", "number", 42)',
          ),
        ),
        _node('nachfolger'),
      ],
      edges: [_edge('script', 'nachfolger')],
    );

    final expressions = templateExpressionSuggestions(
      graph: graph,
      targetNodeId: const NodeId('nachfolger'),
    ).map((s) => s.expression);

    expect(expressions, contains('{{summe}}'));
    expect(expressions, isNot(contains('{{script}}')));
  });
}

WorkflowNode _node(String id) => WorkflowNode(
  id: NodeId(id),
  title: id,
  description: '',
  outputName: id,
  config: const StringInputNodeConfig(value: ''),
);

WorkflowNode _scriptNode() => const WorkflowNode(
  id: NodeId('script'),
  title: 'Berechnung',
  description: '',
  outputName: 'script',
  config: ScriptNodeConfig(script: 'kunde = input\nanzahl = 2\noutput = kunde'),
);

WorkflowEdge _edge(String from, String to) =>
    WorkflowEdge(from: NodeId(from), to: NodeId(to));

WorkflowNode _saveDocumentNode() => const WorkflowNode(
  id: NodeId('speichern'),
  title: 'Datensatz speichern',
  description: '',
  outputName: 'speichern',
  outputFieldNames: {'created': 'Angelegt', 'count': 'Anzahl'},
  config: SaveDocumentNodeConfig(
    collectionName: 'kunden',
    filters: [],
    fields: [DocumentFieldAssignment(field: 'name', value: '')],
  ),
);

WorkflowNode _structuredPromptNode() => const WorkflowNode(
  id: NodeId('prompt'),
  title: 'Prompt',
  description: '',
  config: PromptNodeConfig(
    instruction: '',
    outputType: PromptOutputType.structured,
    choices: [],
    structuredFields: [StructuredOutputField(name: 'titel', description: '')],
  ),
);
