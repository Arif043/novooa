part of 'task_homepage_cubit.dart';

sealed class TaskHomepageState extends Equatable {
  const TaskHomepageState();

  @override
  List<Object> get props => [];
}

final class TaskHomepageLoading extends TaskHomepageState {
  const TaskHomepageLoading();
}

final class TaskHomepageReady extends TaskHomepageState {
  const TaskHomepageReady(this.tasks);

  final List<Task> tasks;

  @override
  List<Object> get props => [tasks];
}

final class TaskHomepageFailure extends TaskHomepageState {
  const TaskHomepageFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
