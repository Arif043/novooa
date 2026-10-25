import 'package:equatable/equatable.dart';

import '../../../../shared/domain/ids.dart';
import 'run_interaction.dart';

export '../../../../shared/domain/ids.dart';
export 'run_interaction.dart';

/// Status eines Laufs, wie ihn die Runtime meldet.
enum RunStatus {
  queued,
  running,
  waitingForApproval,
  rejected,
  succeeded,
  failed;

  static RunStatus fromName(String name) => RunStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => RunStatus.queued,
  );

  bool get isFinished =>
      this == succeeded || this == failed || this == rejected;
}

class TaskRun extends Equatable {
  const TaskRun({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.status,
    required this.updatedAt,
    this.finalOutput = '',
    this.interaction,
  });

  final RunId id;
  final TaskId taskId;
  final String taskTitle;
  final RunStatus status;
  final DateTime updatedAt;

  /// Ergebnis des letzten Bausteins; leer, solange der Lauf nicht fertig ist.
  final String finalOutput;

  /// Was der Lauf von dir braucht, solange er wartet.
  final RunInteraction? interaction;

  bool get needsReview => status == RunStatus.waitingForApproval;

  @override
  List<Object?> get props => [id, status, updatedAt, finalOutput, interaction];
}

enum RunReviewDecision { approve, reject }

enum RunReviewFailure { rejected, unreachable }
