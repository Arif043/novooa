import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_graph_layers.dart';

import 'knowledge_graph_simulation_test.dart' show note, simulationOf;

const _layers = KnowledgeGraphLayers(spacing: 120, margin: 48);
const _canvas = Size(1200, 760);

/// Wie im Bildschirmfoto: 8 → 7 → 1 → 2 … 6.
final _chain = [
  note('8', ['7']),
  note('7', ['1']),
  note('1', ['2', '3', '4', '5', '6']),
  for (final id in ['2', '3', '4', '5', '6']) note(id),
];

void main() {
  test('zählt direkt und indirekt verlinkte Notizen, ohne Backlinks', () {
    expect(KnowledgeGraphLayers.reachCountsOf(_chain), {
      '8': 7,
      '7': 6,
      '1': 5,
      '2': 0,
      '3': 0,
      '4': 0,
      '5': 0,
      '6': 0,
    });
    final cycle = [
      note('a', ['b']),
      note('b', ['a']),
    ];
    expect(KnowledgeGraphLayers.reachCountsOf(cycle), {'a': 1, 'b': 1});
  });

  test('mehr erreichte Notizen stehen höher, gleich viele in einer Reihe', () {
    final positions = _layers.positionsOf(_chain, _canvas);

    expect(positions['8']!.dy, lessThan(positions['7']!.dy));
    expect(positions['7']!.dy, lessThan(positions['1']!.dy));
    expect(positions['1']!.dy, lessThan(positions['2']!.dy));
    final leaves = ['2', '3', '4', '5', '6'].map((id) => positions[id]!);
    expect(leaves.map((p) => p.dy).toSet(), hasLength(1));
    expect(leaves.map((p) => p.dx).toSet(), hasLength(5));
  });

  test('eine zu breite Ebene bricht um und alles passt auf die Leinwand', () {
    final notes = [for (var i = 0; i < 60; i++) note('n$i')];
    final positions = _layers.positionsOf(notes, _canvas);

    expect(positions.values.map((p) => p.dy).toSet().length, greaterThan(1));
    for (final position in positions.values) {
      expect((Offset.zero & _canvas).contains(position), isTrue);
    }
  });

  test('der Graph startet nach Höhe und behält die Reihenfolge', () {
    final simulation = simulationOf(_chain);
    double y(String id) => simulation.positions[id]!.dy;
    expect(y('8'), lessThan(y('7')));

    simulation.settle();

    expect(y('8'), lessThan(y('7')));
    expect(y('7'), lessThan(y('1')));
  });
}
