import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/services/knowledge_note_reach.dart';

KnowledgeNote note(String id, [List<String> links = const []]) => KnowledgeNote(
  id: id,
  knowledgeBaseId: 'default',
  title: id,
  path: '$id.md',
  content: '',
  outgoingLinks: links,
  updatedAt: DateTime(2026),
);

void main() {
  const reach = KnowledgeNoteReach();

  test('folgt nur ausgehenden Links, direkt und indirekt, mit Ebene', () {
    final notes = [
      note('a', ['b']),
      note('b', ['c', 'a']),
      note('c'),
      note('rueck', ['a']),
      note('fremd'),
    ];

    expect(reach('a', notes), {'a': 0, 'b': 1, 'c': 2});
  });

  test('endet nach fünf Ebenen', () {
    final notes = [
      for (var i = 0; i < 8; i++) note('n$i', ['n${i + 1}']),
    ];

    expect(reach('n0', notes).keys, ['n0', 'n1', 'n2', 'n3', 'n4', 'n5']);
  });

  test('nimmt höchstens 50 Notizen, die nächsten zuerst', () {
    final notes = [
      note('start', [for (var i = 0; i < 60; i++) 'n$i']),
      for (var i = 0; i < 60; i++) note('n$i'),
    ];

    final reached = reach('start', notes);

    expect(reached, hasLength(50));
    expect(reached.containsKey('n48'), isTrue);
    expect(reached.containsKey('n49'), isFalse);
  });

  test('unbekannte Ziele und Notizen ergeben nichts', () {
    expect(
      reach('a', [
        note('a', ['fehlt']),
      ]),
      {'a': 0},
    );
    expect(reach('fehlt', [note('a')]), isEmpty);
  });
}
