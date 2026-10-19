import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/teamwork_conversation_entry.dart';
import 'package:syscat2/features/activity/infrastructure/models/teamwork_conversation_mapper.dart';

void main() {
  test('reads tasks, reviews and results of a teamwork conversation', () {
    final conversation = teamworkConversationFrom([
      {
        'kind': 'task',
        'occurredAt': '2026-10-19T08:00:00.000Z',
        'memberName': 'Elektriker',
        'text': 'Prüfe den Plan.',
        'expectedResult': 'Ja/Nein',
        'boundaries': ' ',
      },
      {
        'kind': 'reviewRejected',
        'occurredAt': '2026-10-19T08:01:00.000Z',
        'text': 'Kosten fehlen.',
        'round': 2,
      },
    ]);

    expect(conversation.map((entry) => entry.kind), [
      TeamworkConversationKind.task,
      TeamworkConversationKind.reviewRejected,
    ]);
    expect(conversation.first.expectedResult, 'Ja/Nein');
    expect(conversation.first.boundaries, isNull);
    expect(conversation.first.occurredAt, DateTime.utc(2026, 10, 19, 8));
    expect(conversation.last.round, 2);
  });

  test(
    'skips unknown kinds and broken entries, and reads no list as empty',
    () {
      final conversation = teamworkConversationFrom([
        {'kind': 'gossip', 'occurredAt': '2026-10-19T08:00:00Z', 'text': 'x'},
        {'kind': 'answer', 'text': 'ohne Zeitpunkt'},
        'kein Eintrag',
      ]);

      expect(conversation, isEmpty);
      expect(teamworkConversationFrom(null), isEmpty);
    },
  );
}
