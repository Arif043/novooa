import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_homepage_cubit.dart';

void main() {
  test('load stellt gespeicherte Aufgaben bereit', () async {
    final cubit = TaskHomepageCubit(_FakeTaskRepository([_task]));

    await cubit.load();

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks, [_task]);

    await cubit.close();
  });

  test('load meldet Fehler bei Ladefehler', () async {
    final cubit = TaskHomepageCubit(_FailingTaskRepository());

    await cubit.load();

    expect(cubit.state, isA<TaskHomepageFailure>());

    await cubit.close();
  });
}

const _task = Task(
  id: 'task.1',
  title: 'Angebot prüfen',
  objective: '',
  selectedNodeId: NodeId(''),
  graph: WorkflowGraph(nodes: [], edges: []),
);

class _FakeTaskRepository implements TaskRepository {
  const _FakeTaskRepository(this.tasks);

  final List<Task> tasks;

  @override
  Future<List<Task>> loadTasks() async => tasks;

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(
      TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
    );
  }
}

class _FailingTaskRepository extends _FakeTaskRepository {
  _FailingTaskRepository() : super(const []);

  @override
  Future<List<Task>> loadTasks() {
    throw StateError('failed');
  }
}
