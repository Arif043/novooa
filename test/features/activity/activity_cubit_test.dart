import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/domain/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/repositories/task_activity_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/list_task_activities.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_cubit.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_state.dart';

class _Repository implements TaskActivityRepository {
  _Repository(this.activities);

  final List<TaskActivity> activities;

  @override
  Future<void> add(TaskActivity activity) async {
    activities.add(activity);
  }

  @override
  Future<List<TaskActivity>> listRecent() async {
    return activities;
  }
}

void main() {
  test('ActivityCubit laedt Aktivitaeten', () async {
    final cubit = ActivityCubit(
      listTaskActivities: ListTaskActivities(_Repository([_activity()])),
    );

    await cubit.load();

    expect(cubit.state.status, ActivityLoadStatus.ready);
    expect(cubit.state.activities.single.taskTitle, 'Testaufgabe');
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
