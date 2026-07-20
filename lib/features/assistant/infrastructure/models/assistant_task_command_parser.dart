import 'dart:convert';

import '../../domain/entities/assistant_task_command.dart';

class ParsedAssistantAnswer {
  const ParsedAssistantAnswer({required this.text, required this.commands});

  final String text;
  final List<AssistantTaskCommand> commands;
}

class AssistantTaskCommandParser {
  const AssistantTaskCommandParser();

  ParsedAssistantAnswer parse(String rawAnswer) {
    final match = _commandBlock.firstMatch(rawAnswer);
    if (match == null) {
      return ParsedAssistantAnswer(text: rawAnswer, commands: const []);
    }
    final commandJson = match.namedGroup('json')?.trim() ?? '';
    return ParsedAssistantAnswer(
      text: rawAnswer.replaceFirst(match.group(0) ?? '', '').trim(),
      commands: _commandsFrom(commandJson),
    );
  }

  List<AssistantTaskCommand> _commandsFrom(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return const [];
      final commands = decoded['commands'];
      if (commands is! List) return const [];
      return commands
          .whereType<Map>()
          .map(_commandFrom)
          .where((command) => command.type.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

AssistantTaskCommand _commandFrom(Map value) {
  return AssistantTaskCommand.fromJson(Map<String, Object?>.from(value));
}

final _commandBlock = RegExp(
  r'```novooa_task_plan\s*(?<json>[\s\S]*?)```',
  multiLine: true,
);
