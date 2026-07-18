class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory AssistantMessage.user(String text) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory AssistantMessage.agent(String text) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.agent,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final AssistantMessageRole role;
  final String text;
  final DateTime createdAt;
}

enum AssistantMessageRole { user, agent }
