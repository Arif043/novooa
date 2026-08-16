import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/task_activity.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/usecases/review_task_run.dart';
import '../../domain/usecases/watch_task_activities.dart';
import '../../domain/usecases/watch_task_runs.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    required WatchTaskActivities watchTaskActivities,
    required WatchTaskRuns watchTaskRuns,
    required ReviewTaskRun reviewTaskRun,
  }) : this._(watchTaskActivities, watchTaskRuns, reviewTaskRun);

  ActivityCubit._(
    this._watchTaskActivities,
    this._watchTaskRuns,
    this._reviewTaskRun,
  ) : super(const ActivityState());

  final WatchTaskActivities _watchTaskActivities;
  final WatchTaskRuns _watchTaskRuns;
  final ReviewTaskRun _reviewTaskRun;
  StreamSubscription<List<TaskActivity>>? _activitiesSubscription;
  StreamSubscription<List<TaskRun>>? _runsSubscription;
  List<TaskActivity> _activities = const [];
  List<TaskRun> _runs = const [];

  Future<void> load() async {
    emit(const ActivityState());
    _activitiesSubscription?.cancel();
    _runsSubscription?.cancel();
    _activitiesSubscription = _watchTaskActivities().listen(
      _onActivities,
      onError: (_) => _emitFailure(),
    );
    _runsSubscription = _watchTaskRuns().listen(
      _onRuns,
      onError: (_) => _emitFailure(),
    );
  }

  Future<void> approveRun(TaskRun run, String output) async {
    await _reviewTaskRun(
      run: run,
      decision: TaskRunReviewDecision.approve,
      output: output,
    );
  }

  Future<void> rejectRun(TaskRun run) async {
    await _reviewTaskRun(
      run: run,
      decision: TaskRunReviewDecision.reject,
      output: '',
    );
  }

  Future<void> submitDialogInput(TaskRun run, Map<String, Object?> values) {
    return _reviewTaskRun(
      run: run,
      decision: TaskRunReviewDecision.approve,
      output: '',
      formValues: values,
    );
  }

  void _onActivities(List<TaskActivity> activities) {
    _activities = activities;
    _emitReady();
  }

  void _onRuns(List<TaskRun> runs) {
    _runs = runs;
    _emitReady();
  }

  void _emitReady() {
    if (!isClosed) {
      emit(
        ActivityState(
          status: ActivityLoadStatus.ready,
          activities: _activities,
          runs: _runs,
        ),
      );
    }
  }

  void _emitFailure() {
    if (!isClosed) {
      emit(
        const ActivityState(
          status: ActivityLoadStatus.failure,
          message: 'Aktivitäten konnten nicht geladen werden.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _activitiesSubscription?.cancel();
    await _runsSubscription?.cancel();
    return super.close();
  }
}
