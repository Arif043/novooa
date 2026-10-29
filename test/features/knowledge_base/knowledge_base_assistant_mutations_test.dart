import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_state.dart';

import 'knowledge_base_test_doubles.dart';

void main() {
  late MemoryKnowledgeBaseRepository repository;
  late KnowledgeBaseCubit cubit;
  setUp(() {
    repository = MemoryKnowledgeBaseRepository();
    cubit = memoryKnowledgeBaseCubit(repository);
  });
  tearDown(() => cubit.close());
  test('erstellt einen vom Agenten vorgeschlagenen Eintrag', () async {
    final note = await cubit.createSuggestedNote(
      title: 'Projektstart',
      content: '# Projektstart',
    );
    expect(note.title, 'Projektstart');
    expect(cubit.state.notes.single.content, '# Projektstart');
  });
  test('bearbeitet einen vom Agenten vorgeschlagenen Eintrag', () async {
    final original = await cubit.createSuggestedNote(
      title: 'Alt',
      content: 'Vorher',
    );
    final updated = await cubit.updateSuggestedNote(
      noteId: original.id,
      title: 'Neu',
      content: 'Nachher',
    );
    expect(updated.title, 'Neu');
    expect(cubit.state.notes.single.content, 'Nachher');
  });
  test('löscht einen vom Agenten vorgeschlagenen Eintrag', () async {
    final note = await cubit.createSuggestedNote(title: 'Löschen', content: '');
    await cubit.deleteSuggestedNote(note.id);
    expect(cubit.state.notes, isEmpty);
  });

  test('stellt einen gelöschten Eintrag für Rückgängig wieder her', () async {
    final note = await cubit.createSuggestedNote(
      title: 'Wiederherstellen',
      content: 'Inhalt',
    );
    await cubit.deleteSuggestedNote(note.id);
    await cubit.restoreSuggestedNote(note);
    expect(cubit.state.notes.single.id, note.id);
    expect(cubit.state.notes.single.content, 'Inhalt');
  });

  test('speichert automatisch ohne Erfolgsmeldung', () async {
    final note = await cubit.createSuggestedNote(title: 'Notiz', content: '');
    cubit.selectNote(note.id);
    cubit.updateContent('Neuer Inhalt');
    expect(cubit.state.isSaving, isTrue);

    await Future<void>.delayed(
      KnowledgeBaseCubit.saveDelay + const Duration(milliseconds: 50),
    );

    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.message, isNull);
    expect(cubit.state.status, KnowledgeBaseStatus.ready);
  });
}
