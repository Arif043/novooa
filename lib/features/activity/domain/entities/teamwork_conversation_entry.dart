/// Was im Gespräch einer Teamarbeit geschah.
enum TeamworkConversationKind {
  /// Der Orchestrator gibt einem Mitarbeiter einen Auftrag.
  task,

  /// Ein Mitarbeiter antwortet dem Orchestrator.
  answer,

  /// Ein Auftrag an einen Mitarbeiter ist gescheitert.
  failure,

  /// Die Prüfung hat das Ergebnis angenommen.
  reviewPassed,

  /// Die Prüfung hat das Ergebnis beanstandet.
  reviewRejected,

  /// Das Ergebnis, das der Orchestrator abgibt.
  result,
}

/// Ein Eintrag im Gespräch der Mitarbeiter einer Teamarbeit, wie ihn die Runtime aufzeichnet.
class TeamworkConversationEntry {
  const TeamworkConversationEntry({
    required this.kind,
    required this.occurredAt,
    required this.text,
    this.memberId,
    this.memberName,
    this.expectedResult,
    this.boundaries,
    this.duration,
    this.round,
  });

  final TeamworkConversationKind kind;
  final DateTime occurredAt;

  /// Auftrag, Antwort, Fehlermeldung, Befund der Prüfung oder das Ergebnis als JSON.
  final String text;

  /// Der Mitarbeiter bei Auftrag, Antwort und Fehler: seine ID bestimmt seine
  /// Farbe, der Name steht im Kopf.
  final String? memberId;
  final String? memberName;
  final String? expectedResult;
  final String? boundaries;

  /// Wie lange der Mitarbeiter für seine Antwort brauchte.
  final Duration? duration;

  /// Runde der Prüfung, ab 1.
  final int? round;
}
