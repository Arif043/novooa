import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas_layout.dart';

// Deckt zu, wohin `CanvasLink.labels[i].editTarget` fachlich zeigt — das ist
// die Grundlage dafür, dass ein Doppelklick auf einen Leinwand-Chip
// (`_CanvasLabelChip`) den richtigen Cubit-Aufruf mit dem richtigen Ziel
// auslöst. Alle Werte — auch Felder flacher Bausteine — tragen ein
// OutputEditTarget mit ihrem Schlüssel.
void main() {
  test(
    'der Hauptwert eines einfachen Bausteins trägt ein OutputEditTarget',
    () {
      const successor = WorkflowNode(
        id: NodeId('next'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      const source = WorkflowNode(
        id: NodeId('quelle'),
        title: '',
        description: '',
        outputs: [WorkflowOutput.primary('ergebnis')],
        config: StringInputNodeConfig(value: ''),
      );
      final layout = WorkflowCanvasLayout(
        const WorkflowGraph(
          nodes: [source, successor],
          edges: [WorkflowEdge(from: NodeId('quelle'), to: NodeId('next'))],
        ),
      );
      final link = layout.links.firstWhere(
        (link) => link.from == 'quelle' && link.to == 'next',
      );
      expect(link.labels, hasLength(1));
      expect(link.labels.single.text, 'ergebnis');
      expect(
        link.labels.single.editTarget,
        isA<OutputEditTarget>()
            .having((target) => target.nodeId, 'nodeId', const NodeId('quelle'))
            .having((target) => target.key, 'key', 'value'),
      );
    },
  );

  test('zeigt nur die Werte mit gesetztem Flag auf der Leinwand', () {
    const successor = WorkflowNode(
      id: NodeId('next'),
      title: '',
      description: '',
      config: StringInputNodeConfig(value: ''),
    );
    final source = WorkflowNode(
      id: const NodeId('suche'),
      title: '',
      description: '',
      outputs: const [
        WorkflowOutput.primary('Datensatz'),
        WorkflowOutput(key: 'found', name: 'Gefunden', showOnCanvas: true),
        WorkflowOutput(key: 'record', name: 'Eintrag'),
      ],
      config: DocumentLookupNodeConfig.initial(),
    );
    final layout = WorkflowCanvasLayout(
      WorkflowGraph(
        nodes: [source, successor],
        edges: const [WorkflowEdge(from: NodeId('suche'), to: NodeId('next'))],
      ),
    );

    final link = layout.links.firstWhere((link) => link.from == 'suche');
    expect(link.labels.map((label) => label.text), ['Datensatz', 'Gefunden']);
  });

  test('ein Feld einer strukturierten Prompt-Ausgabe trägt ein '
      'OutputEditTarget mit dem Feldnamen als Schlüssel', () {
    const successor = WorkflowNode(
      id: NodeId('next'),
      title: '',
      description: '',
      config: StringInputNodeConfig(value: ''),
    );
    const source = WorkflowNode(
      id: NodeId('prompt'),
      title: '',
      description: '',
      outputs: [
        WorkflowOutput(key: 'summe', name: 'Summe', showOnCanvas: true),
        WorkflowOutput(key: 'notiz', name: 'Notiz'),
      ],
      config: PromptNodeConfig(
        instruction: '',
        outputType: PromptOutputType.structured,
        choices: [],
        structuredFields: [
          StructuredOutputField(name: 'summe', description: ''),
          StructuredOutputField(name: 'notiz', description: ''),
        ],
      ),
    );
    final layout = WorkflowCanvasLayout(
      const WorkflowGraph(
        nodes: [source, successor],
        edges: [WorkflowEdge(from: NodeId('prompt'), to: NodeId('next'))],
      ),
    );

    final link = layout.links.firstWhere((link) => link.from == 'prompt');
    expect(link.labels.map((label) => label.text), ['Summe']);
    expect(
      link.labels.single.editTarget,
      isA<OutputEditTarget>().having((target) => target.key, 'key', 'summe'),
    );
  });

  test('ein Bedingungs-Branch-Label trägt ein ConditionalBranchEditTarget mit '
      'Knoten- und Branch-Id', () {
    const decision = WorkflowNode(
      id: NodeId('decision'),
      title: '',
      description: '',
      config: ConditionalNodeConfig(
        branches: [
          ConditionalBranch(
            id: 'branch.1',
            label: 'Ja',
            graph: WorkflowGraph(nodes: [], edges: []),
          ),
        ],
      ),
    );
    final layout = WorkflowCanvasLayout(
      const WorkflowGraph(nodes: [decision], edges: []),
    );
    final link = layout.links.firstWhere(
      (link) =>
          link.from == 'decision' && link.to == '@empty:decision:branch.1',
    );
    expect(link.labels, hasLength(1));
    expect(link.labels.single.text, 'Ja');
    expect(
      link.labels.single.editTarget,
      isA<ConditionalBranchEditTarget>()
          .having(
            (target) => target.conditionalNodeId,
            'conditionalNodeId',
            const NodeId('decision'),
          )
          .having((target) => target.branchId, 'branchId', 'branch.1'),
    );
  });

  test('strukturelle Labels ("Für jedes Element") bleiben ohne Edit-Ziel', () {
    const forEach = WorkflowNode(
      id: NodeId('loop'),
      title: '',
      description: '',
      config: ForEachNodeConfig(
        itemsPointer: '',
        graph: WorkflowGraph(nodes: [], edges: []),
      ),
    );
    final layout = WorkflowCanvasLayout(
      const WorkflowGraph(nodes: [forEach], edges: []),
    );
    final link = layout.links.firstWhere(
      (link) => link.from == 'loop' && link.to == '@empty:loop:',
    );
    expect(link.labels.single.text, 'Für jedes Element');
    expect(link.labels.single.editTarget, isNull);
  });

  test('ein von einer Kante übersteuertes conditionLabel bleibt ohne Edit-Ziel '
      '(kein lebendiger Mutationspfad)', () {
    const source = WorkflowNode(
      id: NodeId('branching'),
      title: '',
      description: '',
      outputs: [WorkflowOutput.primary('branching')],
      config: StringInputNodeConfig(value: ''),
    );
    const successor = WorkflowNode(
      id: NodeId('next'),
      title: '',
      description: '',
      config: StringInputNodeConfig(value: ''),
    );
    final layout = WorkflowCanvasLayout(
      const WorkflowGraph(
        nodes: [source, successor],
        edges: [
          WorkflowEdge(
            from: NodeId('branching'),
            to: NodeId('next'),
            conditionLabel: 'Ja',
          ),
        ],
      ),
    );
    final link = layout.links.firstWhere(
      (link) => link.from == 'branching' && link.to == 'next',
    );
    expect(link.labels.single.text, 'Ja');
    expect(link.labels.single.editTarget, isNull);
  });
}
