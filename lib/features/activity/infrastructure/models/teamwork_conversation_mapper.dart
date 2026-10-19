import '../../domain/entities/teamwork_conversation_entry.dart';

/// Liest das Gespräch einer Teamarbeit; Einträge unbekannter Art oder ohne
/// Text und Zeitpunkt werden übersprungen.
List<TeamworkConversationEntry> teamworkConversationFrom(Object? value) {
  if (value is! List) return const [];
  return List.unmodifiable(
    value
        .whereType<Map>()
        .map(_entryFrom)
        .whereType<TeamworkConversationEntry>(),
  );
}

TeamworkConversationEntry? _entryFrom(Map<dynamic, dynamic> data) {
  final kind = TeamworkConversationKind.values
      .where((kind) => kind.name == data['kind'])
      .firstOrNull;
  final text = data['text'];
  final occurredAt = DateTime.tryParse('${data['occurredAt']}');
  if (kind == null || text is! String || occurredAt == null) return null;
  final durationMs = data['durationMs'];
  final round = data['round'];
  return TeamworkConversationEntry(
    kind: kind,
    occurredAt: occurredAt,
    text: text,
    memberName: _optionalString(data['memberName']),
    expectedResult: _optionalString(data['expectedResult']),
    boundaries: _optionalString(data['boundaries']),
    duration: durationMs is num
        ? Duration(milliseconds: durationMs.round())
        : null,
    round: round is num ? round.toInt() : null,
  );
}

String? _optionalString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
