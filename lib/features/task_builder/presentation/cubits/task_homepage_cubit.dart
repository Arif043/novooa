import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'task_homepage_state.dart';

class TaskHomepageCubit extends Cubit<TaskHomepageState> {
  TaskHomepageCubit() : super(TaskHomepageInitial());
}
