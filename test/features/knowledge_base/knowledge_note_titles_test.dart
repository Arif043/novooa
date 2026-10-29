import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_failure.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/services/knowledge_note_draft_factory.dart';
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

  test('speichert einen vergebenen Titel nicht und meldet ihn', () async {
    await cubit.createSuggestedNote(title: 'Fristen', content: '');
    final note = await cubit.createSuggestedNote(title: 'Mahnung', content: '');
    cubit.selectNote(note.id);

    cubit.updateTitle('FRISTEN');
    await Future<void>.delayed(
      KnowledgeBaseCubit.saveDelay + const Duration(milliseconds: 50),
    );

    expect(repository.updates, 0);
    expect(
      cubit.state.message,
      const KnowledgeFailure(KnowledgeFailureKind.duplicateTitle).message,
    );
    expect(cubit.state.isSaving, isFalse);
  });

  test('speichert, sobald der Titel wieder eindeutig ist', () async {
    await cubit.createSuggestedNote(title: 'Fristen', content: '');
    final note = await cubit.createSuggestedNote(title: 'Mahnung', content: '');
    cubit.selectNote(note.id);

    cubit.updateTitle('Fristen');
    cubit.updateTitle('Fristen 2026');
    await Future<void>.delayed(
      KnowledgeBaseCubit.saveDelay + const Duration(milliseconds: 50),
    );

    expect(repository.updates, 1);
    expect(cubit.state.message, isNull);
    expect(cubit.state.status, KnowledgeBaseStatus.ready);
  });

  test('neue Notizen bekommen den ersten freien Namen', () {
    final taken = [_note('a', 'Neue Notiz 1'), _note('b', 'neue notiz 3')];

    expect(const KnowledgeNoteDraftFactory().newTitle(taken), 'Neue Notiz 2');
    expect(
      const KnowledgeNoteDraftFactory().newTitle(const []),
      'Neue Notiz 1',
    );
  });
}

KnowledgeNote _note(String id, String title) => KnowledgeNote(
  id: id,
  knowledgeBaseId: 'default',
  title: title,
  path: '',
  content: '',
  outgoingLinks: const [],
  updatedAt: DateTime(2026),
);
