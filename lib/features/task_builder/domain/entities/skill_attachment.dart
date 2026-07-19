import 'package:equatable/equatable.dart';

/// Verweis auf eine Fähigkeit (Skill), die einem Baustein angehängt wurde.
/// Enthält nur die Referenzdaten — der SKILL.md-Inhalt liegt in Firebase
/// Storage und wird zur Laufzeit des Runs vom Backend geladen und über die
/// Genkit-Skills-Middleware bereitgestellt.
class SkillAttachment extends Equatable {
  const SkillAttachment({
    required this.skillId,
    required this.title,
    required this.description,
    required this.storagePath,
  });

  final String skillId;
  final String title;
  final String description;
  final String storagePath;

  /// Stabiler Identifier für Set-Operationen und UI-Deduplikation.
  String get id => skillId;

  @override
  List<Object?> get props => [skillId, title, description, storagePath];
}
