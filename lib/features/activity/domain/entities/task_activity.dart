import '../../../../core/entities/unique_id.dart';
import 'activity_failure_code.dart';
import 'teamwork_conversation_entry.dart';

export 'activity_failure_code.dart';
export 'teamwork_conversation_entry.dart';

enum TaskActivityTarget { task, node }

enum TaskActivityStatus { started, succeeded, failed, skipped, waiting }

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.runId,
    required this.taskId,
    required this.taskTitle,
    required this.target,
    required this.status,
    required this.occurredAt,
    this.nodeId,
    this.primitive,
    this.input,
    this.output,
    this.message,
    this.failureCode,
    this.failureDetails = const {},
    this.outputs = const {},
    this.stdout = '',
    this.stderr = '',
    this.conversation = const [],
  });

  final UniqueId id;
  final UniqueId runId;
  final String taskId;
  final String taskTitle;
  final TaskActivityTarget target;
  final TaskActivityStatus status;
  final DateTime occurredAt;
  final String? nodeId;
  final String? primitive;
  final String? input;
  final String? output;
  final String? message;

  /// Ursache eines gescheiterten Bausteins, falls die Runtime sie kennt.
  final ActivityFailureCode? failureCode;

  /// Felder zum [failureCode] (z. B. Operator und erhaltener Wert), die die
  /// Übersetzung einsetzt.
  final Map<String, String> failureDetails;
  final Map<String, Object?> outputs;

  /// Was der Baustein auf stdout und stderr ausgegeben hat (Script-Baustein); leer, wenn nichts.
  final String stdout;
  final String stderr;

  bool get hasConsoleOutput => stdout.isNotEmpty || stderr.isNotEmpty;

  /// Das Gespräch der Mitarbeiter einer Teamarbeit; leer bei anderen Bausteinen.
  final List<TeamworkConversationEntry> conversation;

  bool get hasConversation => conversation.isNotEmpty;
}
