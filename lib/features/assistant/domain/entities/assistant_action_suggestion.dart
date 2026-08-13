enum AssistantActionTarget { taskBuilder, knowledgeBase }

class AssistantActionSuggestion {
  AssistantActionSuggestion({
    required this.target,
    required this.type,
    required this.label,
    required Map<String, Object?> arguments,
  }) : arguments = Map.unmodifiable(arguments);

  final AssistantActionTarget target;
  final String type;
  final String label;
  final Map<String, Object?> arguments;

  String? stringArgument(String name) {
    final value = arguments[name];
    return value is String ? value : null;
  }
}
