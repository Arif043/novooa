import 'package:equatable/equatable.dart';

class AssistantContext extends Equatable {
  const AssistantContext({
    required this.area,
    required this.route,
    this.languageCode = 'en',
  });

  final AssistantArea area;
  final String route;

  /// Sprache, in der der Agent antworten soll (`en` oder `de`).
  final String languageCode;

  String get label {
    return switch (area) {
      AssistantArea.taskBuilder => 'Aufgaben bauen',
      AssistantArea.knowledgeBase => 'Wissensbasis pflegen',
      AssistantArea.general => 'novooa verwenden',
    };
  }

  @override
  List<Object?> get props => [area, route, languageCode];
}

enum AssistantArea { taskBuilder, knowledgeBase, general }
