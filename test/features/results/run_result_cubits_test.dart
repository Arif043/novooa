import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_runs.dart';
import 'package:syscat2/features/results/domain/entities/run_result.dart';
import 'package:syscat2/features/results/domain/entities/run_result_failure.dart';
import 'package:syscat2/features/results/domain/repositories/run_result_repository.dart';
import 'package:syscat2/features/results/domain/usecases/load_run_result.dart';
import 'package:syscat2/features/results/presentation/cubits/run_result_cubit.dart';
import 'package:syscat2/features/results/presentation/cubits/run_result_state.dart';
import 'package:syscat2/features/results/presentation/cubits/run_results_cubit.dart';
import 'package:syscat2/features/results/presentation/cubits/run_results_state.dart';

import 'support/run_result_fixtures.dart';

void main() {
  group('RunResultCubit', () {
    late RunResultCubit cubit;

    setUp(() async {
      cubit = RunResultCubit(LoadRunResult(_Results(fail: false)));
      await cubit.load(testRun);
    });

    tearDown(() => cubit.close());

    RunResultReady ready() => cubit.state as RunResultReady;

    test('wählt eine vorhandene Runde und ignoriert eine fehlende', () {
      cubit.selectRound('schleife', 1);
      expect(ready().roundOf('schleife'), 1);

      cubit.selectRound('schleife', 5);
      expect(ready().roundOf('schleife'), 1);
    });

    test('öffnet und schließt die Details eines Bausteins', () {
      cubit.selectNode('liste');
      expect(ready().selectedNodeId, 'liste');

      cubit.clearSelection();
      expect(ready().selectedNodeId, isNull);
    });

    test('ein Fehler beim Laden lässt sich erneut versuchen', () async {
      final failing = RunResultCubit(LoadRunResult(_Results(fail: true)));
      await failing.load(testRun);
      expect(failing.state, isA<RunResultError>());
      await failing.close();
    });
  });

  test('RunResultsCubit filtert nach Status', () async {
    final runs = StreamController<List<TaskRun>>();
    final cubit = RunResultsCubit(WatchTaskRuns(_Runs(runs.stream)))..load();
    final failed = TaskRun(
      id: testRun.id,
      taskId: 't',
      taskTitle: 'Gescheitert',
      status: TaskRunStatus.failed,
      updatedAt: DateTime(2026),
    );
    runs.add([testRun, failed]);
    await Future<void>.delayed(Duration.zero);

    cubit.filterByStatus(TaskRunStatus.failed);

    final state = cubit.state as RunResultsReady;
    expect(state.visibleRuns.map((run) => run.taskTitle), ['Gescheitert']);
    expect(state.presentStatuses, {
      TaskRunStatus.succeeded,
      TaskRunStatus.failed,
    });
    await cubit.close();
    await runs.close();
  });
}

class _Results implements RunResultRepository {
  _Results({required this.fail});

  final bool fail;

  @override
  Future<Result<RunResult, RunResultFailure>> load(TaskRun run) async =>
      fail ? const Error(RunResultFailure.loadFailed) : Success(testResult());
}

class _Runs implements TaskRunRepository {
  _Runs(this.stream);

  final Stream<List<TaskRun>> stream;

  @override
  Stream<List<TaskRun>> watchRecent() => stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
