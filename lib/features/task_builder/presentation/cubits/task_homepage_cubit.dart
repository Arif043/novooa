import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

part 'task_homepage_state.dart';

class TaskHomepageCubit extends Cubit<TaskHomepageState> {
  TaskHomepageCubit(this._repository) : super(const TaskHomepageLoading());

  final TaskRepository _repository;

  Future<void> load() async {
    emit(const TaskHomepageLoading());
    try {
      final tasks = await _repository.loadTasks();
      if (isClosed) return;
      emit(TaskHomepageReady(tasks));
    } catch (_) {
      if (isClosed) return;
      emit(const TaskHomepageFailure('Aufgaben konnten nicht geladen werden.'));
    }
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
}
