import 'assistant_action_suggestion.dart';
import 'assistant_url_source.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.actionSuggestions = const [],
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
    List<AssistantActionSuggestion> actionSuggestions = const [],
    List<AssistantUrlSource> urlSources = const [],
  }) {
    return AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.agent,
      text: text,
      createdAt: DateTime.now(),
      actionSuggestions: actionSuggestions,
      urlSources: urlSources,
    );
  }

  final String id;
  final AssistantMessageRole role;
  final String text;
  final DateTime createdAt;
  final List<AssistantActionSuggestion> actionSuggestions;
  final List<AssistantUrlSource> urlSources;
}

enum AssistantMessageRole { user, agent }
