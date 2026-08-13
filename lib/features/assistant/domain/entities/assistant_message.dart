import 'assistant_knowledge_command.dart';
import 'assistant_task_command.dart';
import 'assistant_url_source.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.taskCommands = const [],
    this.knowledgeCommands = const [],
    this.urlSources = const [],
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
    List<AssistantKnowledgeCommand> knowledgeCommands = const [],
    List<AssistantUrlSource> urlSources = const [],
  }) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.agent,
      text: text,
      createdAt: DateTime.now(),
      taskCommands: taskCommands,
      knowledgeCommands: knowledgeCommands,
      urlSources: urlSources,
    );
  }

  final String id;
  final AssistantMessageRole role;
  final String text;
  final DateTime createdAt;
  final List<AssistantTaskCommand> taskCommands;
  final List<AssistantKnowledgeCommand> knowledgeCommands;
  final List<AssistantUrlSource> urlSources;
}

enum AssistantMessageRole { user, agent }
