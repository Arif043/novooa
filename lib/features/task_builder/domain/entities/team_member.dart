part of 'node_config.dart';

/// Ein Mitarbeiter im Baustein „Teamarbeit“. Die Zuständigkeit steht im
/// Baustein, nicht beim Mitarbeiter: Sie ist je Aufgabe verschieden und wird
/// die Beschreibung, nach der der Orchestrator Aufträge vergibt.
class TeamMember extends Equatable {
  const TeamMember({
    required this.employeeId,
    this.responsibility = '',
    this.languageModelId = '',
  });

  final String employeeId;
  final String responsibility;

  /// Leer = Standardmodell.
  final String languageModelId;

  bool get hasResponsibility => responsibility.trim().isNotEmpty;

  TeamMember copyWith({String? responsibility, String? languageModelId}) {
    return TeamMember(
      employeeId: employeeId,
      responsibility: responsibility ?? this.responsibility,
      languageModelId: languageModelId ?? this.languageModelId,
    );
  }

  @override
  List<Object?> get props => [employeeId, responsibility, languageModelId];
}
