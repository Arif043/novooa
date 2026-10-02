import 'dart:async';

import '../entities/task_save_notice.dart';

/// Verteilt Rückmeldungen des Speicherns an die Oberfläche (Observer).
///
/// Der Task-Builder speichert automatisch nach jeder Änderung. Damit derselbe
/// Hinweis nicht bei jedem Speichern wiederkehrt, meldet der Bus eine
/// Rückmeldung nur, wenn sie sich gegenüber der letzten derselben Aufgabe
/// geändert hat.
class TaskSaveNoticeBus {
  final _controller = StreamController<TaskSaveNotice>.broadcast();
  final _lastMessages = <String, Set<String>>{};

  Stream<TaskSaveNotice> get notices => _controller.stream;

  void announceWarnings(String taskId, List<String> warnings) {
    if (!_changed(taskId, warnings.toSet())) return;
    for (final warning in warnings) {
      _controller.add(
        TaskSaveNotice(taskId: taskId, message: warning, isRejection: false),
      );
    }
  }

  void announceRejection(String taskId, String message) {
    if (!_changed(taskId, {message})) return;
    _controller.add(
      TaskSaveNotice(taskId: taskId, message: message, isRejection: true),
    );
  }

  /// Ein Speichern ohne Besonderheiten setzt die Erinnerung zurück.
  void clear(String taskId) => _lastMessages.remove(taskId);

  bool _changed(String taskId, Set<String> messages) {
    final previous = _lastMessages[taskId];
    final unchanged =
        previous != null &&
        previous.length == messages.length &&
        previous.containsAll(messages);
    if (unchanged) return false;
    _lastMessages[taskId] = messages;
    return true;
  }
}
