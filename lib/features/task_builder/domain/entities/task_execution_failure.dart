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
        'Lokaler Genkit-Server ist nicht erreichbar.',
      TaskExecutionFailureKind.localExecutionTimeout =>
        'Aufgabe dauert länger als erwartet. Bitte prüfe die Backend-Logs.',
      TaskExecutionFailureKind.invalidResponse =>
        'Genkit hat eine ungültige Antwort geliefert.',
      TaskExecutionFailureKind.executionFailed =>
        'Aufgabe konnte nicht ausgeführt werden.',
    };
  }
}
