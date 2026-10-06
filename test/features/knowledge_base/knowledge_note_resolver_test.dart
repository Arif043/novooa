import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/services/knowledge_note_resolver.dart';

void main() {
  const resolver = KnowledgeNoteResolver();
  final note = KnowledgeNote(
    id: 'note.details',
    knowledgeBaseId: 'default',
    title: 'Details',
    path: 'ordner/details.md',
    content: '',
    outgoingLinks: const [],
    updatedAt: DateTime(2026),
  );

  test('findet eine Notiz über ID, Titel und Pfad mit und ohne .md', () {
    for (final target in ['note.details', ' details ', 'ordner/details.md', 'Ordner/Details']) {
      expect(resolver.resolve(target, [note]), note, reason: target);
    }
  });

  test('liefert nichts für unbekannte oder leere Ziele', () {
    expect(resolver.resolve('fehlt', [note]), isNull);
    expect(resolver.resolve('  ', [note]), isNull);
  });
}
