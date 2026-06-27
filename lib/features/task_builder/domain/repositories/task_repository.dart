import '../entities/task.dart';

/// Vertrag für die Persistenz von [Task]-Entwürfen.
///
/// Wird in der Domain-Schicht deklariert und in `infrastructure/` durch
/// konkrete Implementierungen (aktuell `InMemory`, später Firestore)
/// erfüllt. Die Cubit-Schicht hängt ausschließlich von diesem Interface.
abstract interface class TaskRepository {
  Future<List<Task>> loadTasks();
  Future<void> saveTask(Task task);
}
