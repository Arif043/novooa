import 'package:equatable/equatable.dart';

import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';

/// Ein Mitarbeiter (Subagent) — eine wiederverwendbare Rolle mit fester
/// Prompt-Vorlage und einer Menge Default-Skills. Wird technisch als
/// `ai.definePrompt`-artiger Bauplan verstanden: der Executor rendert die
/// Vorlage mit der node-spezifischen Anweisung und ruft das Modell mit
/// `system = role` und den gemergten Skills als Middleware auf.
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.promptTemplate,
    required this.defaultSkills,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// System-Prompt, der die Rolle des Mitarbeiters beschreibt.
  final String role;

  /// User-Prompt-Vorlage. `{{instruction}}` wird beim Ausführen durch die
  /// Anweisung des Bausteins ersetzt; wenn `{{instruction}}` fehlt, wird
  /// die Anweisung angehängt.
  final String promptTemplate;

  /// Fähigkeiten, die dieser Mitarbeiter automatisch mitbringt.
  final List<SkillAttachment> defaultSkills;

  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    promptTemplate,
    defaultSkills,
    updatedAt,
  ];
}
