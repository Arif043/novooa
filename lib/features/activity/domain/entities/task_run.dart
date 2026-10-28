import '../../../../core/entities/unique_id.dart';

import 'task_run_dialog_input_field.dart';
import 'task_run_interaction.dart';

enum TaskRunStatus {
  queued,
  running,
  waitingForApproval,
  rejected,
  succeeded,
  failed;

  static TaskRunStatus fromName(String name) {
    return TaskRunStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => TaskRunStatus.queued,
    );
  }
}

enum TaskRunReviewDecision { approve, reject }

class TaskRun {
  const TaskRun({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.status,
    required this.updatedAt,
    this.createdAt,
    this.waitingNodeId,
    this.finalOutput,
    this.reviewOutput,
    this.interaction,
    this.message,
    this.startedAt,
    this.completedAt,
    this.triggerType,
    this.startedByName,
  });

  final UniqueId id;
  final String taskId;
  final String taskTitle;
  final TaskRunStatus status;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final String? waitingNodeId;
  final String? finalOutput;
  final String? reviewOutput;
  final TaskRunInteraction? interaction;
  final String? message;

  /// Beginn und Ende der Ausführung; fehlen, solange sie nicht begonnen bzw. geendet hat.
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Auslöserart bei automatischen Läufen (`schedule`, `event`, …).
  final String? triggerType;

  /// Wer den Lauf von Hand gestartet hat.
  final String? startedByName;

  Duration? get duration {
    final start = startedAt;
    final end = completedAt;
    if (start == null || end == null || end.isBefore(start)) return null;
    return end.difference(start);
  }

  String? get reviewInstruction => interaction?.instruction;

  List<TaskRunDialogInputField> get dialogInputFields {
    return interaction?.dialogInputFields ?? const [];
  }

  bool get requiresDialogInput {
    return interaction?.type == TaskRunInteractionType.dialogInput;
  }
}
