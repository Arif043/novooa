import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas_layout.dart';

// Deckt zu, wohin `CanvasLink.labels[i].editTarget` fachlich zeigt — das ist
// die Grundlage dafür, dass ein Doppelklick auf einen Leinwand-Chip
// (`_CanvasLabelChip`) den richtigen Cubit-Aufruf mit dem richtigen Ziel
// auslöst. Besonderes Augenmerk auf den Fall, dass leere Feldnamen aus der
// Anzeige gefiltert werden, das Edit-Ziel aber trotzdem den echten
// Original-Index tragen muss (siehe `_fieldLabels` in
// `workflow_canvas_layout.dart`).
void main() {
  test(
    'der Ausgabename eines einfachen Bausteins trägt ein OutputNameEditTarget',
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
        outputName: 'ergebnis',
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
        isA<OutputNameEditTarget>().having(
          (target) => target.nodeId,
          'nodeId',
          const NodeId('quelle'),
        ),
      );
    },
  );

  test(
    'strukturierte Prompt-Felder tragen den echten Original-Index, auch '
    'wenn ein davorliegendes Feld einen leeren Namen hat und deshalb aus '
    'der Anzeige gefiltert wird',
    () {
      const promptNode = WorkflowNode(
        id: NodeId('prompt'),
        title: '',
        description: '',
        outputName: 'prompt',
        config: PromptNodeConfig(
          instruction: '',
          outputType: PromptOutputType.structured,
          choices: [],
          structuredFields: [
            StructuredOutputField(name: '', description: ''),
            StructuredOutputField(name: 'Alter', description: ''),
          ],
        ),
      );
      const successor = WorkflowNode(
        id: NodeId('next'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      final layout = WorkflowCanvasLayout(
        const WorkflowGraph(
          nodes: [promptNode, successor],
          edges: [WorkflowEdge(from: NodeId('prompt'), to: NodeId('next'))],
        ),
      );
      final link = layout.links.firstWhere(
        (link) => link.from == 'prompt' && link.to == 'next',
      );
      // Nur "Alter" wird angezeigt (leerer Name gefiltert), aber sein
      // fieldIndex bleibt 1 — der echte Index in `structuredFields`, nicht 0
      // (der Index in der gefilterten Anzeigeliste).
      expect(link.labels, hasLength(1));
      expect(link.labels.single.text, 'Alter');
      expect(
        link.labels.single.editTarget,
        isA<StructuredFieldEditTarget>()
            .having((target) => target.nodeId, 'nodeId', const NodeId('prompt'))
            .having((target) => target.fieldIndex, 'fieldIndex', 1),
      );
    },
  );

  test(
    'Dialogeingabe-Felder tragen ebenfalls den echten Original-Index bei '
    'gefilterten leeren Feldnamen',
    () {
      const dialogNode = WorkflowNode(
        id: NodeId('dialog'),
        title: '',
        description: '',
        config: DialogInputNodeConfig(
          instruction: '',
          fields: [
            DialogInputField(name: 'Name', type: DialogInputFieldType.string),
            DialogInputField(name: '', type: DialogInputFieldType.string),
            DialogInputField(name: 'Alter', type: DialogInputFieldType.string),
          ],
        ),
      );
      const successor = WorkflowNode(
        id: NodeId('next'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      final layout = WorkflowCanvasLayout(
        const WorkflowGraph(
          nodes: [dialogNode, successor],
          edges: [WorkflowEdge(from: NodeId('dialog'), to: NodeId('next'))],
        ),
      );
      final link = layout.links.firstWhere(
        (link) => link.from == 'dialog' && link.to == 'next',
      );
      expect(link.labels.map((label) => label.text), ['Name', 'Alter']);
      expect(
        link.labels[0].editTarget,
        isA<DialogFieldEditTarget>()
            .having((target) => target.nodeId, 'nodeId', const NodeId('dialog'))
            .having((target) => target.fieldIndex, 'fieldIndex', 0),
      );
      expect(
        link.labels[1].editTarget,
        isA<DialogFieldEditTarget>()
            .having((target) => target.nodeId, 'nodeId', const NodeId('dialog'))
            .having((target) => target.fieldIndex, 'fieldIndex', 2),
      );
    },
  );

  test(
    'ein Bedingungs-Branch-Label trägt ein ConditionalBranchEditTarget mit '
    'Knoten- und Branch-Id',
    () {
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
        (link) => link.from == 'decision' && link.to == '@empty:decision:branch.1',
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
    },
  );

  test(
    'strukturelle Labels ("Für jedes Element") bleiben ohne Edit-Ziel',
    () {
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
    },
  );

  test(
    'ein von einer Kante übersteuertes conditionLabel bleibt ohne Edit-Ziel '
    '(kein lebendiger Mutationspfad)',
    () {
      const source = WorkflowNode(
        id: NodeId('branching'),
        title: '',
        description: '',
        outputName: 'branching',
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
    },
  );
}
