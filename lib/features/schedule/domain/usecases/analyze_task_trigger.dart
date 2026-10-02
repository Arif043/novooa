import '../entities/create_task_trigger_input.dart';
import '../entities/trigger_cycle_analysis.dart';
import '../repositories/task_trigger_repository.dart';

class AnalyzeTaskTrigger {
  const AnalyzeTaskTrigger(this._repository);

  final TaskTriggerRepository _repository;

  Future<TriggerCycleAnalysis> call(CreateTaskTriggerInput input) {
    return _repository.analyzeTrigger(input);
  }
}
