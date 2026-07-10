import 'package:bloc/bloc.dart';

import '../../domain/usecases/list_task_activities.dart';
import '../../domain/usecases/list_task_runs.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    required ListTaskActivities listTaskActivities,
    required ListTaskRuns listTaskRuns,
  }) : this._(listTaskActivities, listTaskRuns);

  ActivityCubit._(this._listTaskActivities, this._listTaskRuns)
    : super(const ActivityState());

  final ListTaskActivities _listTaskActivities;
  final ListTaskRuns _listTaskRuns;

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
}
