import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

part 'task_homepage_state.dart';

class TaskHomepageCubit extends Cubit<TaskHomepageState> {
  TaskHomepageCubit(this._repository) : super(const TaskHomepageLoading());

  final TaskRepository _repository;
  StreamSubscription<List<Task>>? _subscription;

  Future<void> load() async {
    emit(const TaskHomepageLoading());
    _subscription?.cancel();
    _subscription = _repository.watchTasks().listen(
      _emitTasks,
      onError: (_) => _emitLoadFailure(),
    );
  }

  Future<void> duplicateTask(Task task) async {
    final tasks = _readyTasksOrNull();
    if (tasks == null) return;
    final duplicatedTask = task.duplicate(title: _copyTitle(task.title));
    await _persistTaskListUpdate(() => _repository.saveTask(duplicatedTask), [
      ...tasks,
      duplicatedTask,
    ]);
  }

  Future<void> renameTask(Task task, String title) async {
    final tasks = _readyTasksOrNull();
    final normalizedTitle = title.trim();
    if (tasks == null || normalizedTitle.isEmpty) return;
    final renamedTask = task.copyWith(title: normalizedTitle);
    await _persistTaskListUpdate(
      () => _repository.saveTask(renamedTask),
      tasks.map((item) => item.id == task.id ? renamedTask : item).toList(),
    );
  }

  Future<void> updateObjective(Task task, String objective) async {
    final tasks = _readyTasksOrNull();
    final normalizedObjective = objective.trim();
    if (tasks == null || task.objective == normalizedObjective) return;
    final updatedTask = task.copyWith(objective: normalizedObjective);
    await _persistTaskListUpdate(
      () => _repository.saveTask(updatedTask),
      tasks.map((item) => item.id == task.id ? updatedTask : item).toList(),
    );
  }

  Future<void> deleteTask(Task task) async {
    final tasks = _readyTasksOrNull();
    if (tasks == null) return;
    await _persistTaskListUpdate(
      () => _repository.deleteTask(task.id),
      tasks.where((item) => item.id != task.id).toList(),
    );
  }

  List<Task>? _readyTasksOrNull() {
    final current = state;
    return current is TaskHomepageReady ? current.tasks : null;
  }

  Future<void> _persistTaskListUpdate(
    Future<void> Function() persist,
    List<Task> nextTasks,
  ) async {
    try {
      await persist();
      if (!isClosed) emit(TaskHomepageReady(nextTasks));
    } catch (_) {
      if (!isClosed) {
        emit(
          const TaskHomepageFailure('Aufgabe konnte nicht geändert werden.'),
        );
      }
    }
  }

  String _copyTitle(String title) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) return 'Kopie';
    return 'Kopie von $normalizedTitle';
  }

  void _emitTasks(List<Task> tasks) {
    if (!isClosed) emit(TaskHomepageReady(tasks));
  }

  void _emitLoadFailure() {
    if (!isClosed) {
      emit(const TaskHomepageFailure('Aufgaben konnten nicht geladen werden.'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
