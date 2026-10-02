import 'package:equatable/equatable.dart';

/// Verweis auf eine Fähigkeit (Skill), die einem Baustein angehängt wurde.
/// [name] ist der Ordnername im Skills-Ordner; die Beschreibung dient nur der
/// Anzeige. Der Ordner selbst wird erst zur Laufzeit des Runs vom Backend
/// gelesen und über die Genkit-Skills-Middleware bereitgestellt.
class SkillAttachment extends Equatable {
  const SkillAttachment({required this.name, required this.description});

  final String name;
  final String description;

  /// Stabiler Identifier für Set-Operationen und UI-Deduplikation.
  String get id => name;

  @override
  List<Object?> get props => [name, description];
}
