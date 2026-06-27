import 'package:bloc/bloc.dart';

import '../../domain/usecases/list_task_activities.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({required ListTaskActivities listTaskActivities})
    : _listTaskActivities = listTaskActivities,
      super(const ActivityState());

  final ListTaskActivities _listTaskActivities;

  Future<void> load() async {
    emit(const ActivityState());
    try {
      final activities = await _listTaskActivities();
      if (isClosed) return;
      emit(
        ActivityState(status: ActivityLoadStatus.ready, activities: activities),
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
