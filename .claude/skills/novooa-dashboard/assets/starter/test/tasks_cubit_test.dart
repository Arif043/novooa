import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/domain/entities/dashboard_task.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/domain/usecases/start_task.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/domain/usecases/watch_dashboard_tasks.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/presentation/cubits/task_start_cubit.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/presentation/cubits/tasks_cubit.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/presentation/cubits/tasks_state.dart';

import 'fakes.dart';

const _invoice = DashboardTask(id: TaskId('b'), title: 'Rechnung');
const _offer = DashboardTask(id: TaskId('a'), title: 'Angebot');
const _hidden = DashboardTask(id: TaskId('x'), title: 'Intern');

void main() {
  test('zeigt nur angebotene Aufgaben, alphabetisch', () async {
    final catalog = FakeTaskCatalog();
    final cubit = TasksCubit(
      WatchDashboardTasks(catalog, isOffered: (id) => id.value != 'x'),
    )..load();

    catalog.tasks.add([_invoice, _hidden, _offer]);
    await pumpEventQueue();

    expect((cubit.state as TasksLoaded).tasks, [_offer, _invoice]);
    await cubit.close();
  });

  test('meldet einen Ladefehler und lädt nach „Erneut versuchen“', () async {
    final catalog = FakeTaskCatalog();
    final cubit = TasksCubit(
      WatchDashboardTasks(catalog, isOffered: (_) => true),
    )..load();

    catalog.tasks.addError(Exception('offline'));
    await pumpEventQueue();
    expect(cubit.state, isA<TasksFailure>());

    cubit.load();
    catalog.tasks.add(const []);
    await pumpEventQueue();
    expect((cubit.state as TasksLoaded).tasks, isEmpty);
    await cubit.close();
  });

  test('startet eine Aufgabe mit Eingabe und meldet den Lauf', () async {
    final catalog = FakeTaskCatalog();
    final cubit = TaskStartCubit(StartTask(catalog));

    await cubit.start(_invoice, context: '  Kunde 42 ');

    expect(catalog.starts, [(const TaskId('b'), 'Kunde 42')]);
    expect(cubit.state, isA<TaskStarted>());
    await cubit.close();
  });

  test('meldet einen abgelehnten Start', () async {
    final catalog = FakeTaskCatalog()
      ..startResult = const Error(TaskStartFailure.rejected);
    final cubit = TaskStartCubit(StartTask(catalog));

    await cubit.start(_invoice);

    expect((cubit.state as TaskStartFailed).failure, TaskStartFailure.rejected);
    await cubit.close();
  });
}
