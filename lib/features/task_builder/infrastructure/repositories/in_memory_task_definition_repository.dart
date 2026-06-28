import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// In-Memory-Implementierung des [TaskRepository].
///
/// Seedet einen dreiköpfigen Beispiel-Flow, damit der Builder sofort
/// etwas Sichtbares hat. Überlebt keinen App-Restart — der Migrationspfad
/// zu Firestore ist in `docs/architecture.md` § Persistenz dokumentiert.
class InMemoryTaskDefinitionRepository implements TaskRepository {
  final List<Task> _draft = [];

  @override
  Future<List<Task>> loadTasks() async {
    return _draft;
  }

  @override
  Future<void> saveTask(Task task) async {
    _draft.add(task);
  }
}
