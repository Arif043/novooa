import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_physics.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_base_graph_view.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_canvas.dart';

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
  test(
    'dragging moves linked neighbours gently and leaves unrelated nodes still',
    () {
      final rest = {
        'a': const Offset(300, 300),
        'b': const Offset(500, 300),
        'isolated': const Offset(800, 500),
      };
      final positions = Map<String, Offset>.of(rest)
        ..['a'] = const Offset(400, 300);
      final velocities = <String, Offset>{};
      final physics = KnowledgeGraphPhysics(
        notes: [
          note('a', ['b']),
          note('b'),
          note('isolated'),
        ],
        canvasSize: const Size(1200, 760),
        pinnedNoteId: 'a',
        restPositions: rest,
      );
      for (var i = 0; i < 120; i++) {
        final before = positions['b']!;
        physics.step(positions, velocities);
        expect((positions['b']! - before).distance, lessThanOrEqualTo(5));
      }
      expect(positions['isolated'], rest['isolated']);
      expect(positions['b']!.dx, inExclusiveRange(500, 550));
      rest['a'] = positions['a']!;
      var moving = true;
      for (var i = 0; i < 240; i++) {
        moving = physics.step(positions, velocities);
      }
      expect(moving, false);
      expect((positions['b']! - rest['b']!).distance, lessThan(1));
      expect(positions['a'], const Offset(400, 300));
    },
  );

  test('reciprocal and duplicate links do not multiply the force', () {
    final rest = {'a': const Offset(300, 300), 'b': const Offset(500, 300)};
    Map<String, Offset> run(List<KnowledgeNote> notes) {
      final positions = Map<String, Offset>.of(rest)
        ..['a'] = const Offset(400, 300);
      final velocities = <String, Offset>{};
      final physics = KnowledgeGraphPhysics(
        notes: notes,
        canvasSize: const Size(1200, 760),
        pinnedNoteId: 'a',
        restPositions: rest,
      );
      for (var i = 0; i < 60; i++) {
        physics.step(positions, velocities);
      }
      return positions;
    }

    expect(
      run([
        note('a', ['b']),
        note('b'),
      ]),
      run([
        note('a', ['a', 'b', 'b', 'missing']),
        note('b', ['a']),
      ]),
    );
  });

  testWidgets('a dropped node stays put and the simulation settles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeBaseGraphView(
            notes: [
              note('a', ['b']),
              note('b'),
              note('isolated'),
            ],
            selectedNoteId: 'a',
          ),
        ),
      ),
    );
    final canvas = tester.widget<KnowledgeGraphCanvas>(
      find.byType(KnowledgeGraphCanvas),
    );
    final before = Map<String, Offset>.of(canvas.positions);
    canvas.onNodeDragStart('a');
    await tester.pump();
    canvas.onNodeDrag('a', before['a']!, const Offset(60, 40));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final dropped = canvas.positions['a'];
    canvas.onNodeDragEnd();
    await tester.pumpAndSettle();
    expect(canvas.positions['a'], dropped);
    expect(canvas.positions['isolated'], before['isolated']);
    expect((canvas.positions['b']! - before['b']!).distance, lessThan(1));
    expect(tester.takeException(), isNull);
  });
  test('grabbing a stationary node does not disturb the layout', () {
    final positions = {
      'a': const Offset(300, 300),
      'b': const Offset(500, 300),
      'isolated': const Offset(800, 500),
    };
    final before = Map<String, Offset>.of(positions);
    final physics = KnowledgeGraphPhysics(
      notes: [
        note('a', ['b']),
        note('b'),
        note('isolated'),
      ],
      canvasSize: const Size(1200, 760),
      pinnedNoteId: 'a',
    );
    final velocities = <String, Offset>{};
    for (var i = 0; i < 60; i++) {
      physics.step(positions, velocities);
    }
    expect(positions, before);
  });
}
