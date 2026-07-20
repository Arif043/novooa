import 'assistant_task_command.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.taskCommands = const [],
  });

  factory AssistantMessage.user(String text) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory AssistantMessage.agent(
    String text, {
    List<AssistantTaskCommand> taskCommands = const [],
  }) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.agent,
      text: text,
      createdAt: DateTime.now(),
      taskCommands: taskCommands,
    );
  }

  final String id;
  final AssistantMessageRole role;
  final String text;
  final DateTime createdAt;
  final List<AssistantTaskCommand> taskCommands;
}

enum AssistantMessageRole { user, agent }
