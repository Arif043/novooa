import 'task_run_failure.dart';

enum TaskExecutionFailureKind {
  localServerUnavailable,
  localExecutionTimeout,
  invalidResponse,
  executionFailed,
  invalidTaskRequest,
}

class TaskExecutionFailure {
  const TaskExecutionFailure(this.kind, {this.detail});

  factory TaskExecutionFailure.fromTaskRunFailure(TaskRunFailure? failure) {
    if (failure == null) {
      return const TaskExecutionFailure(
        TaskExecutionFailureKind.executionFailed,
      );
    }
    return TaskExecutionFailure(
      TaskExecutionFailureKind.invalidTaskRequest,
      detail: failure.message,
    );
  }

  final TaskExecutionFailureKind kind;
  final String? detail;

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
      TaskExecutionFailureKind.invalidTaskRequest =>
        detail ?? 'Aufgabe konnte nicht gestartet werden.',
    };
  }
}
