import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/prompt_generation_options_mapper.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

const _promptId = NodeId('prompt.1');
const _mapper = PromptGenerationOptionsMapper();

void main() {
  group('PromptGenerationOptions', () {
    test('ungültige Werte fallen auf den Modellstandard zurück', () {
      const options = PromptGenerationOptions();

      expect(options.withTemperature(2.5).temperature, isNull);
      expect(options.withTemperature(0.7).temperature, 0.7);
      expect(options.withContextWindow(0).contextWindow, isNull);
      expect(options.withMaxOutputTokens(-1).maxOutputTokens, isNull);
    });

    test('ein Wert lässt sich wieder auf den Modellstandard setzen', () {
      final options = const PromptGenerationOptions().withContextWindow(16384);

      expect(options.withContextWindow(null).usesModelDefaults, isTrue);
    });
  });

  group('PromptGenerationOptionsMapper', () {
    test('speichert nur gesetzte Optionen und liest sie zurück', () {
      final options = const PromptGenerationOptions()
          .withContextWindow(16384)
          .withThinking(ThinkingMode.off);

      final document = _mapper.toDocument(options);

      expect(document, {'contextWindow': 16384, 'thinking': 'off'});
      expect(_mapper.fromDocument(document), options);
    });

    test('fehlende oder fremde Daten ergeben den Modellstandard', () {
      expect(_mapper.fromDocument(null), const PromptGenerationOptions());
      expect(
        _mapper.fromDocument({'thinking': 'unbekannt', 'temperature': 'x'}),
        const PromptGenerationOptions(),
      );
    });
  });

  test(
    'updatePromptGenerationOptions speichert die Optionen am Baustein',
    () async {
      final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(_task()));
      await cubit.load(_task());
      final options = const PromptGenerationOptions().withContextWindow(16384);

      await cubit.updatePromptGenerationOptions(_promptId, options);

      final state = cubit.state as TaskBuilderLoaded;
      final config = state.editingTask.nodes.single.config as PromptNodeConfig;
      expect(config.generationOptions, options);
      await cubit.close();
    },
  );
}

Task _task() {
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: _promptId,
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: _promptId,
          title: 'Prompt',
          description: '',
          config: PromptNodeConfig.initial(),
        ),
      ],
      edges: const [],
    ),
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(this.task);

  Task task;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([task]);

  @override
  Future<void> saveTask(Task value) async => task = value;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
  }
}
