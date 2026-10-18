import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

void main() {
  test(
    'ein neues Script startet mit auskommentiertem workflow_output und ohne Werte',
    () async {
      final builder = TaskBuilderCubit(repository: _TaskRepository());
      addTearDown(builder.close);
      await builder.load(_task);
      await builder.addConnectedNode(primitive: WorkflowPrimitive.script);

      final node =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single;
      expect(
        node.config,
        const ScriptNodeConfig(
          script: '# workflow_output("name", "string", wert)',
        ),
      );
      expect(node.outputs, isEmpty);
    },
  );
}

const _task = Task(
  id: 'task.1',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.0'),
  graph: WorkflowGraph(nodes: [], edges: []),
);

class _TaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks() => Stream.value([_task]);

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
}
