import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/repositories/task_activity_repository.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/review_task_run.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_activities.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_runs.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_cubit.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_state.dart';

class _ActivityRepository implements TaskActivityRepository {
  _ActivityRepository(this.activities);

  final List<TaskActivity> activities;

  @override
  Future<void> add(TaskActivity activity) async {
    activities.add(activity);
  }

  @override
  Stream<List<TaskActivity>> watchRecent() {
    return Stream.value(activities);
  }
}

class _RunRepository implements TaskRunRepository {
  const _RunRepository(this.runs);

  final List<TaskRun> runs;

  @override
  Stream<List<TaskRun>> watchRecent() {
    return Stream.value(runs);
  }

  @override
  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
  }) async {}
}

void main() {
  test('ActivityCubit laedt Aktivitaeten', () async {
    final cubit = ActivityCubit(
      watchTaskActivities: WatchTaskActivities(
        _ActivityRepository([_activity()]),
      ),
      watchTaskRuns: WatchTaskRuns(_RunRepository([_run()])),
      reviewTaskRun: ReviewTaskRun(_RunRepository([_run()])),
    );

    cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ActivityLoadStatus.ready);
    expect(cubit.state.activities.single.taskTitle, 'Testaufgabe');
    expect(cubit.state.runs.single.status, TaskRunStatus.waitingForApproval);
    await cubit.close();
  });
}

TaskActivity _activity() {
  return TaskActivity(
    id: const UniqueId('activity.1'),
    runId: const UniqueId('run.1'),
    taskId: 'task.1',
    taskTitle: 'Testaufgabe',
    target: TaskActivityTarget.task,
    status: TaskActivityStatus.started,
    occurredAt: DateTime.utc(2026),
  );
}

TaskRun _run() {
  return TaskRun(
    id: const UniqueId('run.1'),
    taskId: 'task.1',
    taskTitle: 'Testaufgabe',
    status: TaskRunStatus.waitingForApproval,
    updatedAt: DateTime.utc(2026),
  );
}
