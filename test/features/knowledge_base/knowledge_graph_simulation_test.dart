import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_base_graph_view.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_canvas.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_node.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_simulation.dart';

KnowledgeNote note(String id, [List<String> links = const []]) => KnowledgeNote(
  id: id,
  knowledgeBaseId: 'default',
  title: id,
  path: '$id.md',
  content: '',
  outgoingLinks: links,
  updatedAt: DateTime(2026),
);

const _canvas = Size(1200, 760);

KnowledgeGraphSimulation simulationOf(List<KnowledgeNote> notes) =>
    KnowledgeGraphSimulation(canvasSize: _canvas)..setNotes(notes);

double distanceBetween(
  KnowledgeGraphSimulation simulation,
  String a,
  String b,
) => (simulation.positions[a]! - simulation.positions[b]!).distance;

void main() {
  test('unverbundene Notizen stoßen sich ab, verbundene halten Abstand', () {
    final simulation = simulationOf([
      note('a', ['b']),
      note('b'),
      note('c'),
      note('d'),
    ]);
    final unlinkedBefore = distanceBetween(simulation, 'c', 'd');

    simulation.settle();

    expect(distanceBetween(simulation, 'c', 'd'), greaterThan(unlinkedBefore));
    expect(distanceBetween(simulation, 'a', 'b'), inInclusiveRange(70, 220));
  });

  test('der Graph kühlt ab und kommt zur Ruhe', () {
    final simulation = simulationOf([
      note('a', ['b']),
      note('b'),
      note('c'),
    ]);

    expect(simulation.isActive, isTrue);
    simulation.settle();

    expect(simulation.isActive, isFalse);
    final rested = Map<String, Offset>.of(simulation.positions);
    simulation.step();
    for (final id in rested.keys) {
      expect((simulation.positions[id]! - rested[id]!).distance, lessThan(.5));
    }
  });

  test('ein gezogener Knoten bleibt fixiert und hält die Simulation warm', () {
    final simulation = simulationOf([
      note('a', ['b']),
      note('b'),
    ])..settle();
    simulation
      ..startDrag('a')
      ..dragTo('a', const Offset(900, 600));

    for (var i = 0; i < 600; i++) {
      simulation.step();
    }

    expect(simulation.positions['a'], const Offset(900, 600));
    expect(simulation.isActive, isTrue);
    expect(distanceBetween(simulation, 'a', 'b'), lessThan(260));
    simulation.endDrag();
    simulation.settle();
    expect(simulation.isActive, isFalse);
  });

  test('doppelte und gegenseitige Links verstärken die Feder nicht', () {
    final single = simulationOf([
      note('a', ['b']),
      note('b'),
    ])..settle();
    final doubled = simulationOf([
      note('a', ['a', 'b', 'b', 'fehlt']),
      note('b', ['a']),
    ])..settle();

    expect(doubled.links, single.links);
    expect(
      distanceBetween(doubled, 'a', 'b'),
      closeTo(distanceBetween(single, 'a', 'b'), 1),
    );
  });

  test('alle Knoten bleiben innerhalb der Leinwand', () {
    final notes = [for (var i = 0; i < 60; i++) note('n$i')];
    final simulation = simulationOf(notes)..settle();

    for (final position in simulation.positions.values) {
      expect(
        (Offset.zero & _canvas).contains(position),
        isTrue,
        reason: '$position',
      );
    }
  });

  testWidgets(
    'der Graph entfaltet sich, reagiert auf Ziehen und kommt zur Ruhe',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeBaseGraphView(
              notes: [
                note('a', ['b']),
                note('b'),
                note('c'),
              ],
              selectedNoteId: 'a',
            ),
          ),
        ),
      );
      final canvas = tester.widget<KnowledgeGraphCanvas>(
        find.byType(KnowledgeGraphCanvas),
      );
      final unfolding = Map<String, Offset>.of(canvas.positions);
      await _pumpFrames(tester);
      expect(canvas.positions, isNot(unfolding));
      await tester.pumpAndSettle();

      final before = Map<String, Offset>.of(canvas.positions);
      canvas.onNodeDragStart('a');
      canvas.onNodeDrag('a', before['a']!, const Offset(120, 80));
      await _pumpFrames(tester);
      expect(canvas.positions['b'], isNot(before['b']));

      canvas.onNodeDragEnd();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hervorgehoben ist nur, was ein Prompt mit der Notiz sieht', (
    tester,
  ) async {
    await _pumpGraph(tester, [
      note('a', ['b']),
      note('b', ['c']),
      note('c'),
      note('rueck', ['a']),
      note('fremd'),
    ]);
    await tester.pumpAndSettle();

    expect(_emphasisOf(tester, 'a'), KnowledgeGraphEmphasis.selected);
    expect(_emphasisOf(tester, 'b'), KnowledgeGraphEmphasis.directlyLinked);
    expect(_emphasisOf(tester, 'c'), KnowledgeGraphEmphasis.indirectlyLinked);
    expect(_emphasisOf(tester, 'rueck'), KnowledgeGraphEmphasis.dimmed);
    expect(_emphasisOf(tester, 'fremd'), KnowledgeGraphEmphasis.dimmed);
    expect(find.text('3 Notizen im Prompt-Kontext'), findsOneWidget);
  });
}

Future<void> _pumpGraph(WidgetTester tester, List<KnowledgeNote> notes) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: KnowledgeBaseGraphView(notes: notes, selectedNoteId: 'a'),
      ),
    ),
  );
}

KnowledgeGraphEmphasis _emphasisOf(WidgetTester tester, String id) => tester
    .widget<KnowledgeGraphNode>(
      find.byKey(ValueKey('knowledge-graph-node-$id')),
    )
    .emphasis;

/// Einzelne 16-ms-Frames, wie im echten Betrieb; ein langer Frame würde der
/// Simulation nur einen Schritt geben.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
