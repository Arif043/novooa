import 'package:bloc/bloc.dart';

import '../../domain/usecases/list_task_activities.dart';
import '../../domain/usecases/list_task_runs.dart';
import '../../domain/usecases/review_task_run.dart';
import '../../domain/entities/task_run.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    required ListTaskActivities listTaskActivities,
    required ListTaskRuns listTaskRuns,
    required ReviewTaskRun reviewTaskRun,
  }) : this._(listTaskActivities, listTaskRuns, reviewTaskRun);

  ActivityCubit._(
    this._listTaskActivities,
    this._listTaskRuns,
    this._reviewTaskRun,
  ) : super(const ActivityState());

  final ListTaskActivities _listTaskActivities;
  final ListTaskRuns _listTaskRuns;
  final ReviewTaskRun _reviewTaskRun;

  Future<void> load() async {
    emit(const ActivityState());
    try {
      final activities = await _listTaskActivities();
      final runs = await _listTaskRuns();
      if (isClosed) return;
      emit(
        ActivityState(
          status: ActivityLoadStatus.ready,
          activities: activities,
          runs: runs,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const ActivityState(
          status: ActivityLoadStatus.failure,
          message: 'Aktivitäten konnten nicht geladen werden.',
        ),
      );
    }
  }

  Future<void> approveRun(TaskRun run, String output) async {
    await _reviewTaskRun(
      run: run,
      decision: TaskRunReviewDecision.approve,
      output: output,
    );
    await load();
  }

  Future<void> rejectRun(TaskRun run) async {
    await _reviewTaskRun(
      run: run,
      decision: TaskRunReviewDecision.reject,
      output: '',
    );
    await load();
  }
}
