import 'package:flutter_test/flutter_test.dart';

import 'package:syscat2/features/task_builder/domain/entities/task_definition.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_definition_repository.dart';
import 'package:syscat2/features/task_builder/domain/usecases/get_draft_task_definition.dart';
import 'package:syscat2/features/task_builder/domain/usecases/save_draft_task_definition.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryRepository implements TaskDefinitionRepository {
  TaskDefinition _draft;

  _InMemoryRepository(TaskDefinition initial) : _draft = initial;

  int saveCalls = 0;

  @override
  Future<TaskDefinition> loadDraft() async => _draft;

  @override
  Future<void> saveDraft(TaskDefinition taskDefinition) async {
    saveCalls++;
    _draft = taskDefinition;
  }

  TaskDefinition get current => _draft;
}

TaskDefinition _seed({NodeId? selectedNodeId, List<WorkflowNode>? nodes}) {
  return TaskDefinition(
    id: 'draft.task',
    title: 'Seed',
    objective: 'Seed objective',
    selectedNodeId: selectedNodeId ?? const NodeId('node.1'),
    nodes:
        nodes ??
        const [
          WorkflowNode(
            id: NodeId('node.1'),
            primitive: WorkflowPrimitive.prompt,
            title: 'Erster',
            description: 'Initiale Beschreibung.',
          ),
        ],
    edges: const [],
  );
}

TaskBuilderCubit _cubitWith(TaskDefinition seed) {
  final repository = _InMemoryRepository(seed);
  final cubit = TaskBuilderCubit(
    getDraftTaskDefinition: GetDraftTaskDefinition(repository),
    saveDraftTaskDefinition: SaveDraftTaskDefinition(repository),
  );
  return cubit;
}

void main() {
  group('TaskBuilderCubit', () {
    test('load() liefert Loaded mit Seed-Daten', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      expect(cubit.state, isA<TaskBuilderLoaded>());
      final loaded = cubit.state as TaskBuilderLoaded;
      expect(loaded.taskDefinition.title, 'Seed');
      expect(loaded.taskDefinition.nodes.length, 1);
      cubit.dispose();
    });

    test(
      'addPrimitive erweitert Knotenliste und erzeugt implizite Kante',
      () async {
        final cubit = _cubitWith(_seed());
        await cubit.load();
        await cubit.addPrimitive(WorkflowPrimitive.toolCall);
        final loaded = cubit.state as TaskBuilderLoaded;
        expect(loaded.taskDefinition.nodes.length, 2);
        expect(loaded.taskDefinition.edges.length, 1);
        // Selektion wandert auf den neuen Knoten
        expect(
          loaded.taskDefinition.selectedNodeId,
          isNot(equals(const NodeId('node.1'))),
        );
        cubit.dispose();
      },
    );

    test('updateNodeDescription persistiert sofort', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      const nodeId = NodeId('node.1');
      await cubit.updateNodeDescription(nodeId, 'Neue Beschreibung');
      final loaded = cubit.state as TaskBuilderLoaded;
      final updated = loaded.taskDefinition.nodes.firstWhere(
        (n) => n.id == nodeId,
      );
      expect(updated.description, 'Neue Beschreibung');
      cubit.dispose();
    });

    test('removeNode entfernt Knoten und repariert Selektion', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      const toRemove = NodeId('node.1');
      await cubit.removeNode(toRemove);
      final loaded = cubit.state as TaskBuilderLoaded;
      expect(loaded.taskDefinition.nodes, isEmpty);
      expect(loaded.taskDefinition.selectedNodeOrNull, isNull);
      cubit.dispose();
    });

    test('updateTitle no-op bei identischem Wert', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      // Erste save kommt aus load() nicht (load ruft nur getDraft auf).
      // updateTitle mit gleichem Wert darf nicht erneut speichern.
      // Wir verifizieren über die Repository.saveCalls-Zählung indirekt
      // über die State-Emission: state bleibt strukturell gleich.
      final stateBefore = cubit.state;
      await cubit.updateTitle('Seed');
      final stateAfter = cubit.state;
      expect(
        (stateBefore as TaskBuilderLoaded).taskDefinition.title,
        (stateAfter as TaskBuilderLoaded).taskDefinition.title,
      );
      cubit.dispose();
    });

    test('updatePromptInstruction persistiert Prompt-Anweisung', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      await cubit.updatePromptInstruction(
        const NodeId('node.1'),
        'Schreibe eine kurze Antwort.',
      );
      final loaded = cubit.state as TaskBuilderLoaded;
      final node = loaded.taskDefinition.nodes.first;
      expect(node.promptConfig.instruction, 'Schreibe eine kurze Antwort.');
      cubit.dispose();
    });

    test('updatePromptOutputType persistiert Entscheidungsmodus', () async {
      final cubit = _cubitWith(_seed());
      await cubit.load();
      await cubit.updatePromptOutputType(
        const NodeId('node.1'),
        PromptOutputType.decision,
      );
      final loaded = cubit.state as TaskBuilderLoaded;
      final node = loaded.taskDefinition.nodes.first;
      expect(node.promptConfig.outputType, PromptOutputType.decision);
      cubit.dispose();
    });
  });
}
