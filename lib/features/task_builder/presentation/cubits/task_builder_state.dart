import '../../domain/entities/task.dart';

/// Sealed State-Hierarchie für [TaskBuilderCubit].
///
/// UI muss jeden Subtyp in einem erschöpfenden `switch` behandeln — der
/// Analyzer prüft das. `Failure` enthält eine deutsche, UI-fertige
/// Fehlermeldung.
sealed class TaskBuilderState {
  const TaskBuilderState();
}

class TaskBuilderLoading extends TaskBuilderState {
  const TaskBuilderLoading();
}

class TaskBuilderLoaded extends TaskBuilderState {
  const TaskBuilderLoaded(this.editingTask);

  final Task editingTask;
}

class TaskBuilderFailure extends TaskBuilderState {
  const TaskBuilderFailure(this.message);

  final String message;
}
