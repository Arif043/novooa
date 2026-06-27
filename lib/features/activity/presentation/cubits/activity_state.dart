import '../../domain/entities/task_activity.dart';

enum ActivityLoadStatus { loading, ready, failure }

class ActivityState {
  const ActivityState({
    this.status = ActivityLoadStatus.loading,
    this.activities = const [],
    this.message,
  });

  final ActivityLoadStatus status;
  final List<TaskActivity> activities;
  final String? message;

  ActivityState copyWith({
    ActivityLoadStatus? status,
    List<TaskActivity>? activities,
    String? message,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      message: message,
    );
  }
}
