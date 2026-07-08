enum TaskExecutionFailureKind {
  localServerUnavailable,
  localExecutionTimeout,
  invalidResponse,
  executionFailed,
}

class TaskExecutionFailure {
  const TaskExecutionFailure(this.kind);

  final TaskExecutionFailureKind kind;

  String get message {
    return switch (kind) {
      TaskExecutionFailureKind.localServerUnavailable =>
        'Aufgaben-Ausführung ist nicht erreichbar.',
      TaskExecutionFailureKind.localExecutionTimeout =>
        'Aufgabe dauert länger als erwartet. Bitte prüfe die Backend-Logs.',
      TaskExecutionFailureKind.invalidResponse =>
        'Backend hat eine ungültige Antwort geliefert.',
      TaskExecutionFailureKind.executionFailed =>
        'Aufgabe konnte nicht ausgeführt werden.',
    };
  }
}
