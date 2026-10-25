import 'package:multiple_result/multiple_result.dart';

import '../entities/dashboard_task.dart';

/// Aufgaben der Runtime lesen und starten.
abstract interface class TaskCatalog {
  /// Aktuelle Aufgaben; meldet sich bei jeder Änderung neu.
  Stream<List<DashboardTask>> watchTasks();

  /// Startet einen Lauf; [context] ist die Eingabe der Aufgabe.
  Future<Result<RunId, TaskStartFailure>> start(TaskId id, {String context});
}
