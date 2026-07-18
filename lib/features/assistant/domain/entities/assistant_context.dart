import 'package:equatable/equatable.dart';

class AssistantContext extends Equatable {
  const AssistantContext({required this.area, required this.route});

  final AssistantArea area;
  final String route;

  String get label {
    return switch (area) {
      AssistantArea.taskBuilder => 'Aufgaben bauen',
      AssistantArea.knowledgeBase => 'Wissensbasis pflegen',
      AssistantArea.general => 'novooa verwenden',
    };
  }

  @override
  List<Object?> get props => [area, route];
}

enum AssistantArea { taskBuilder, knowledgeBase, general }
