import 'dart:convert';

import '../../domain/entities/assistant_action_suggestion.dart';

class ParsedAssistantAnswer {
  const ParsedAssistantAnswer({
    required this.text,
    required this.actionSuggestions,
  });

  final String text;
  final List<AssistantActionSuggestion> actionSuggestions;
}

class AssistantActionSuggestionParser {
  const AssistantActionSuggestionParser();

  ParsedAssistantAnswer parse(String rawAnswer) {
    final jsonAnswer = _structuredAnswerFrom(rawAnswer);
    if (jsonAnswer != null) return jsonAnswer;
    final match = _commandBlock.firstMatch(rawAnswer);
    if (match == null) {
      return ParsedAssistantAnswer(
        text: rawAnswer,
        actionSuggestions: const [],
      );
    }
    final commandJson = match.namedGroup('json')?.trim() ?? '';
    return ParsedAssistantAnswer(
      text: rawAnswer.replaceFirst(match.group(0) ?? '', '').trim(),
      actionSuggestions: _suggestionsFrom(commandJson),
    );
  }

  ParsedAssistantAnswer? _structuredAnswerFrom(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      final answer = _answerTextFrom(decoded);
      return ParsedAssistantAnswer(
        text: answer.isEmpty ? source : answer,
        actionSuggestions: [
          ..._suggestionsFromMap(
            decoded,
            key: 'commands',
            target: AssistantActionTarget.taskBuilder,
          ),
          ..._suggestionsFromMap(
            decoded,
            key: 'knowledgeCommands',
            target: AssistantActionTarget.knowledgeBase,
          ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  String _answerTextFrom(Map value) {
    final answer = value['answer'];
    if (answer is String) return answer.trim();
    final text = value['text'];
    return text is String ? text.trim() : '';
  }

  List<AssistantActionSuggestion> _suggestionsFrom(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return const [];
      return _suggestionsFromMap(
        decoded,
        key: 'commands',
        target: AssistantActionTarget.taskBuilder,
      );
    } catch (_) {
      return const [];
    }
  }

  List<AssistantActionSuggestion> _suggestionsFromMap(
    Map decoded, {
    required String key,
    required AssistantActionTarget target,
  }) {
    final commands = decoded[key];
    if (commands is! List) return const [];
    return commands
        .whereType<Map>()
        .map((command) => _suggestionFrom(command, target))
        .where((suggestion) => suggestion.type.isNotEmpty)
        .toList(growable: false);
  }
}

AssistantActionSuggestion _suggestionFrom(
  Map value,
  AssistantActionTarget target,
) {
  final arguments = Map<String, Object?>.from(value);
  final type = _requiredText(arguments.remove('type'));
  final label = _requiredText(arguments.remove('label'), fallback: type);
  return AssistantActionSuggestion(
    target: target,
    type: type,
    label: label,
    arguments: arguments,
  );
}

String _requiredText(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

final _commandBlock = RegExp(
  r'```novooa_task_plan\s*(?<json>[\s\S]*?)```',
  multiLine: true,
);
