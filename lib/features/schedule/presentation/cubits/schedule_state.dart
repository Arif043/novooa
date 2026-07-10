import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/task_trigger.dart';

enum ScheduleStatus { loading, ready, failure }

class ScheduleState {
  const ScheduleState({
    this.status = ScheduleStatus.loading,
    this.triggers = const [],
    this.tasks = const [],
    this.message,
  });

  final ScheduleStatus status;
  final List<TaskTrigger> triggers;
  final List<Task> tasks;
  final String? message;

  ScheduleState copyWith({
    ScheduleStatus? status,
    List<TaskTrigger>? triggers,
    List<Task>? tasks,
    String? message,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      triggers: triggers ?? this.triggers,
      tasks: tasks ?? this.tasks,
      message: message,
    );
  }
}
