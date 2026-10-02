/// Rückmeldung der Runtime beim Speichern einer Aufgabe.
///
/// [isRejection]: Die Aufgabe wurde nicht gespeichert (z. B. weil sie sich
/// über einen Auslöser selbst starten würde). Sonst ist es ein Hinweis auf
/// eine mögliche Schleife; gespeichert wurde trotzdem.
class TaskSaveNotice {
  const TaskSaveNotice({
    required this.taskId,
    required this.message,
    required this.isRejection,
  });

  final String taskId;
  final String message;
  final bool isRejection;
}
