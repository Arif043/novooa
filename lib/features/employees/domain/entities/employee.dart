import 'package:equatable/equatable.dart';

/// Ein Mitarbeiter (Subagent): eine wiederverwendbare Rahmenbedingung plus
/// eine Menge Fähigkeiten. Beim Lauf eines Bausteins wird die Rahmenbedingung
/// zum System-Prompt des Modellaufrufs, die Fähigkeiten erhält der Agent
/// implizit. Ein Baustein hat entweder einen Mitarbeiter oder eigene
/// Fähigkeiten — nie beides.
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    required this.constraint,
    this.skillNames = const [],
  });

  final String id;
  final String name;

  /// Rahmenbedingung: gilt als System-Prompt für jeden Aufruf. Darf leer sein.
  final String constraint;

  /// Namen der Fähigkeiten (Ordnernamen im Skills-Verzeichnis).
  final List<String> skillNames;

  @override
  List<Object?> get props => [id, name, constraint, skillNames];
}
