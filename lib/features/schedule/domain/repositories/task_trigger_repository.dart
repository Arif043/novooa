import '../entities/create_task_trigger_input.dart';
import '../entities/task_trigger.dart';
import '../entities/trigger_cycle_analysis.dart';

abstract interface class TaskTriggerRepository {
  Stream<List<TaskTrigger>> watchTriggers();

  /// Prüft vorab, ob der Auslöser eine Schleife erzeugen würde. Varianten ohne
  /// Dateiereignisse liefern [TriggerCycleAnalysis.none].
  Future<TriggerCycleAnalysis> analyzeTrigger(CreateTaskTriggerInput input);

  Future<void> createTrigger(CreateTaskTriggerInput input);

  Future<void> setTriggerEnabled(String triggerId, bool enabled);

  Future<void> deleteTrigger(String triggerId);

  /// Macht die bisherige Webhook-Adresse ungültig und vergibt eine neue.
  Future<void> rotateWebhookToken(String triggerId);
}
