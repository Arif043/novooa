class AssistantKnowledgeCommand {
  const AssistantKnowledgeCommand({
    required this.type,
    required this.label,
    this.noteId,
    this.title,
    this.content,
  });

  factory AssistantKnowledgeCommand.fromJson(Map<String, Object?> json) {
    return AssistantKnowledgeCommand(
      type: _requiredText(json['type']),
      label: _requiredText(
        json['label'],
        fallback: _requiredText(json['type']),
      ),
      noteId: _optionalText(json['noteId']),
      title: _optionalText(json['title']),
      content: _optionalText(json['content']),
    );
  }

  final String type;
  final String label;
  final String? noteId;
  final String? title;
  final String? content;
}

String _requiredText(Object? value, {String fallback = ''}) {
  if (value is! String || value.trim().isEmpty) return fallback;
  return value.trim();
}

String? _optionalText(Object? value) {
  final text = _requiredText(value);
  return text.isEmpty ? null : text;
}
