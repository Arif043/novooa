import 'package:equatable/equatable.dart';

/// Eine Fähigkeit (Skill) — wiederverwendbare Anweisung mit Progressive
/// Disclosure. Wird als SKILL.md-Datei in Firebase Storage abgelegt und bei
/// Bedarf über die Genkit-Skills-Middleware in einen Modell-Turn geladen.
///
/// Metadaten (Titel, Beschreibung, Storage-Pfad) liegen als Firestore-Dokument
/// unter `teams/{teamId}/skills/{skillId}`. Die eigentliche Anleitung liegt
/// unter `teams/{teamId}/skills/{skillId}/SKILL.md` in Storage.
class Skill extends Equatable {
  const Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.storagePath,
    required this.content,
    required this.updatedAt,
  });

  /// Firestore-Dokument-ID des Skills.
  final String id;

  /// Anzeigename der Fähigkeit — wird an das Modell als Skill-Name gereicht.
  final String title;

  /// Kurzbeschreibung, wann diese Fähigkeit einzusetzen ist. Erscheint im
  /// Skill-Manifest, das die Middleware als System-Prompt einbindet.
  final String description;

  /// Storage-Pfad des Skill-Ordners in Firebase Storage.
  /// Muster: `teams/{teamId}/skills/{skillId}`.
  final String storagePath;

  /// Aktueller SKILL.md-Inhalt. Wird bei Save nach Storage geschrieben und
  /// nicht in Firestore gespiegelt — nur beim Bearbeiten im Client gehalten.
  final String content;

  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, description, storagePath, updatedAt];
}
