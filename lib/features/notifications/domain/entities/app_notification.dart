import '../../../../core/entities/unique_id.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../../../activity/domain/entities/task_run_interaction.dart';

enum AppNotificationType { teamInvitation, taskRunApproval, unknown }

enum AppNotificationStatus { pending, accepted, rejected, unknown }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.createdAt,
    this.teamId,
    this.teamName,
    this.runId,
    this.taskId,
    this.taskTitle,
    this.waitingNodeId,
    this.finalOutput,
    this.reviewOutput,
    this.interaction,
  });

  final String id;
  final AppNotificationType type;
  final AppNotificationStatus status;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? teamId;
  final String? teamName;
  final String? runId;
  final String? taskId;
  final String? taskTitle;
  final String? waitingNodeId;
  final String? finalOutput;
  final String? reviewOutput;
  final TaskRunInteraction? interaction;

  bool get isPendingTeamInvitation {
    return type == AppNotificationType.teamInvitation &&
        status == AppNotificationStatus.pending;
  }

  bool get isPendingTaskRunApproval {
    return type == AppNotificationType.taskRunApproval &&
        status == AppNotificationStatus.pending;
  }

  TaskRun? get taskRun {
    if (runId == null || taskId == null) return null;
    return TaskRun(
      id: UniqueId(runId!),
      taskId: taskId!,
      taskTitle: taskTitle ?? 'Unbenannte Aufgabe',
      status: TaskRunStatus.waitingForApproval,
      updatedAt: createdAt,
      waitingNodeId: waitingNodeId,
      finalOutput: finalOutput,
      reviewOutput: reviewOutput,
      interaction: interaction,
    );
  }
}
