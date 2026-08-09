import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_homepage_cubit.dart';

void main() {
  test('load stellt gespeicherte Aufgaben bereit', () async {
    final cubit = TaskHomepageCubit(_FakeTaskRepository([_task]));

    cubit.load();
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks, [_task]);

    await cubit.close();
  });

  test('load meldet Fehler bei Ladefehler', () async {
    final cubit = TaskHomepageCubit(_FailingTaskRepository());

    cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<TaskHomepageFailure>());

    await cubit.close();
  });

  test(
    'uebernimmt nachtraegliche Aenderungen aus dem Aufgabenstream',
    () async {
      final updates = StreamController<List<Task>>();
      final cubit = TaskHomepageCubit(_StreamingTaskRepository(updates.stream));

      await cubit.load();
      updates.add([_task]);
      await Future<void>.delayed(Duration.zero);
      updates.add([_task.copyWith(title: 'Aktualisiert')]);
      await Future<void>.delayed(Duration.zero);

      expect(
        (cubit.state as TaskHomepageReady).tasks.single.title,
        'Aktualisiert',
      );
      await cubit.close();
      await updates.close();
    },
  );

  test('duplicateTask erstellt eine Kopie mit neuer ID', () async {
    final repository = _FakeTaskRepository([_task]);
    final cubit = TaskHomepageCubit(repository);

    cubit.load();
    await Future<void>.delayed(Duration.zero);
    await cubit.duplicateTask(_task);

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks, hasLength(2));
    expect(state.tasks.last.id, isNot(_task.id));
    expect(state.tasks.last.title, 'Kopie von Angebot prüfen');
    expect(repository.tasks, state.tasks);

    await cubit.close();
  });

  test('renameTask aktualisiert den Aufgabennamen', () async {
    final repository = _FakeTaskRepository([_task]);
    final cubit = TaskHomepageCubit(repository);

    cubit.load();
    await Future<void>.delayed(Duration.zero);
    await cubit.renameTask(_task, 'Neuer Name');

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks.single.title, 'Neuer Name');
    expect(repository.tasks.single.title, 'Neuer Name');

    await cubit.close();
  });

  test('updateObjective speichert die Aufgabennotiz', () async {
    final repository = _FakeTaskRepository([_task]);
    final cubit = TaskHomepageCubit(repository);

    cubit.load();
    await Future<void>.delayed(Duration.zero);
    await cubit.updateObjective(_task, '  Quartalsbericht vorbereiten  ');

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks.single.objective, 'Quartalsbericht vorbereiten');
    expect(repository.tasks.single.objective, 'Quartalsbericht vorbereiten');

    await cubit.close();
  });

  test('updateObjective erlaubt leere Notizen', () async {
    final task = _task.copyWith(objective: 'Alte Notiz');
    final repository = _FakeTaskRepository([task]);
    final cubit = TaskHomepageCubit(repository);

    cubit.load();
    await Future<void>.delayed(Duration.zero);
    await cubit.updateObjective(task, '   ');

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks.single.objective, '');
    expect(repository.tasks.single.objective, '');

    await cubit.close();
  });

  test('deleteTask entfernt die Aufgabe', () async {
    final repository = _FakeTaskRepository([_task]);
    final cubit = TaskHomepageCubit(repository);

    await cubit.load();
    await cubit.deleteTask(_task);

    final state = cubit.state as TaskHomepageReady;
    expect(state.tasks, isEmpty);
    expect(repository.tasks, isEmpty);

    await cubit.close();
  });

  test('executeTask delegiert die angeklickte Aufgabe', () async {
    final repository = _FakeTaskRepository([_task]);
    final cubit = TaskHomepageCubit(repository);

    final failureMessage = await cubit.executeTask(_task);

    expect(repository.executedTask, _task);
    expect(failureMessage, 'Aufgabe konnte nicht ausgeführt werden.');
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
  _FakeTaskRepository(this.tasks);

  final List<Task> tasks;
  Task? executedTask;

  @override
  Stream<List<Task>> watchTasks() => Stream.value(tasks);

  @override
  Future<void> saveTask(Task task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
      return;
    }
    tasks[index] = task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<Result<TaskRunStart, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    executedTask = task;
    return const Error(
      TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
    );
  }
}

class _FailingTaskRepository extends _FakeTaskRepository {
  _FailingTaskRepository() : super([]);

  @override
  Stream<List<Task>> watchTasks() {
    return Stream.error(StateError('failed'));
  }
}

class _StreamingTaskRepository implements TaskRepository {
  const _StreamingTaskRepository(this._tasks);

  final Stream<List<Task>> _tasks;

  @override
  Stream<List<Task>> watchTasks() => _tasks;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(
    TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
  );

  @override
  Future<void> saveTask(Task task) async {}
}
