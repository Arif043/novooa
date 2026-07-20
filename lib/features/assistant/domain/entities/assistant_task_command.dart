class AssistantTaskCommand {
  const AssistantTaskCommand({
    required this.type,
    required this.label,
    this.primitive,
    this.kind,
    this.title,
    this.referenceName,
    this.description,
    this.value,
    this.instruction,
    this.recipient,
    this.message,
  });

  factory AssistantTaskCommand.fromJson(Map<String, Object?> json) {
    return AssistantTaskCommand(
      type: _text(json['type']),
      label: _text(json['label'], fallback: _text(json['type'])),
      primitive: _textOrNull(json['primitive']),
      kind: _textOrNull(json['kind']),
      title: _textOrNull(json['title']),
      referenceName: _textOrNull(json['referenceName']),
      description: _textOrNull(json['description']),
      value: _textOrNull(json['value']),
      instruction: _textOrNull(json['instruction']),
      recipient: _textOrNull(json['recipient']),
      message: _textOrNull(json['message']),
    );
  }

  final String type;
  final String label;
  final String? primitive;
  final String? kind;
  final String? title;
  final String? referenceName;
  final String? description;
  final String? value;
  final String? instruction;
  final String? recipient;
  final String? message;
}

String _text(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

String? _textOrNull(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}
