import '../../domain/entities/task_activity.dart';
import '../../domain/entities/task_run.dart';

enum ActivityLoadStatus { loading, ready, failure }

class ActivityState {
  const ActivityState({
    this.status = ActivityLoadStatus.loading,
    this.activities = const [],
    this.runs = const [],
    this.message,
  });

  final ActivityLoadStatus status;
  final List<TaskActivity> activities;
  final List<TaskRun> runs;
  final String? message;

  ActivityState copyWith({
    ActivityLoadStatus? status,
    List<TaskActivity>? activities,
    List<TaskRun>? runs,
    String? message,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      runs: runs ?? this.runs,
      message: message,
    );
  }
}
