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
}
