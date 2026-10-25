import 'package:multiple_result/multiple_result.dart';

import '../entities/dashboard_task.dart';
import '../repositories/task_catalog.dart';

class StartTask {
  const StartTask(this._catalog);

  final TaskCatalog _catalog;

  Future<Result<RunId, TaskStartFailure>> call(
    DashboardTask task, {
    String context = '',
  }) => _catalog.start(task.id, context: context.trim());
}
