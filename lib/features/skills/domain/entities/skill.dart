import 'package:equatable/equatable.dart';

/// Eine Fähigkeit (Skill) nach dem Standard agentskills.io: ein Ordner mit
/// `SKILL.md` (+ `scripts/`, `references/`, `assets/`) im Skills-Ordner des
/// Nutzers. Der Ordner ist die Quelle der Wahrheit; Name und Beschreibung
/// stammen aus dem Kopf der `SKILL.md`.
class Skill extends Equatable {
  const Skill({
    required this.name,
    required this.description,
    required this.fileCount,
    this.license,
    this.compatibility,
    this.warnings = const [],
  });

  /// Ordnername — zugleich der Name, unter dem das Modell den Skill kennt.
  final String name;
  final String description;
  final String? license;
  final String? compatibility;
  final int fileCount;

  /// Probleme, die der Nutzer beheben sollte (fehlende Beschreibung, …).
  final List<String> warnings;

  String get id => name;

  @override
  List<Object?> get props => [
    name,
    description,
    license,
    compatibility,
    fileCount,
    warnings,
  ];
}
