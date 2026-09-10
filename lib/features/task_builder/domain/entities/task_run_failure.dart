enum TaskRunFailureKind {
  runtimeUnavailable,
  executionTimeout,
  invalidResponse,
  executionFailed,
  invalidRequest,
  invalidTaskId,
  invalidReviewDecision,
  invalidFormValues,
}

class TaskRunFailure {
  const TaskRunFailure(this.kind, {this.detail});

  final TaskRunFailureKind kind;
  final String? detail;

  static TaskRunFailure? fromCode(String? code, String message) {
    final kind = switch (code) {
      'invalidRequest' => TaskRunFailureKind.invalidRequest,
      'invalidTaskId' => TaskRunFailureKind.invalidTaskId,
      'invalidReviewDecision' => TaskRunFailureKind.invalidReviewDecision,
      'invalidFormValues' => TaskRunFailureKind.invalidFormValues,
      _ => null,
    };
    return kind == null ? null : TaskRunFailure(kind, detail: message);
  }

  String get message {
    return switch (kind) {
      TaskRunFailureKind.runtimeUnavailable =>
        'Aufgaben-Ausführung ist nicht erreichbar.',
      TaskRunFailureKind.executionTimeout =>
        'Aufgabe dauert länger als erwartet. Bitte prüfe die Backend-Logs.',
      TaskRunFailureKind.invalidResponse =>
        'Backend hat eine ungültige Antwort geliefert.',
      TaskRunFailureKind.executionFailed =>
        'Aufgabe konnte nicht ausgeführt werden.',
      TaskRunFailureKind.invalidRequest ||
      TaskRunFailureKind.invalidTaskId ||
      TaskRunFailureKind.invalidReviewDecision ||
      TaskRunFailureKind.invalidFormValues =>
        detail ?? 'Aufgabe konnte nicht gestartet werden.',
    };
  }
}
