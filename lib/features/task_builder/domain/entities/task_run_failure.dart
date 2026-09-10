enum TaskRunFailureKind {
  invalidRequest,
  invalidTaskId,
  invalidReviewDecision,
  invalidFormValues,
}

class TaskRunFailure {
  const TaskRunFailure({required this.kind, required this.message});

  final TaskRunFailureKind kind;
  final String message;

  static TaskRunFailure? fromCode(String? code, String message) {
    final kind = switch (code) {
      'invalidRequest' => TaskRunFailureKind.invalidRequest,
      'invalidTaskId' => TaskRunFailureKind.invalidTaskId,
      'invalidReviewDecision' => TaskRunFailureKind.invalidReviewDecision,
      'invalidFormValues' => TaskRunFailureKind.invalidFormValues,
      _ => null,
    };
    return kind == null ? null : TaskRunFailure(kind: kind, message: message);
  }
}
