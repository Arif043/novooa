import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';

class BausteinInsertion {
  const BausteinInsertion({this.owner, this.branchId, this.after});
  final NodeId? owner;
  final String? branchId;
  final NodeId? after;
}

class CanvasEntry {
  const CanvasEntry(this.id, this.node, this.insertion, this.peers);
  final String id;
  final WorkflowNode? node;
  final BausteinInsertion insertion;
  final Set<NodeId> peers;
}

class CanvasLink {
  const CanvasLink(this.from, this.to, [this.label]);
  final String from;
  final String to;
  final String? label;
}

/// Presentation-only layout: persisted edges remain the source of truth.
/// Containment links additionally make conditional and loop subplans visible.
class WorkflowCanvasLayout {
  WorkflowCanvasLayout(WorkflowGraph graph, {double textScale = 1})
    : nodeHeight = cardHeight * textScale.clamp(1.0, 3.0) {
    _collect(graph, const BausteinInsertion());
    _arrange();
  }

  static const cardWidth = 340.0;
  static const cardHeight = 120.0;
  final double nodeHeight;
  final entries = <String, CanvasEntry>{};
  final links = <CanvasLink>[];
  final rectangles = <String, Rect>{};
  late final Size size;

  void _collect(
    WorkflowGraph graph,
    BausteinInsertion insertion, {
    String? parent,
    String? label,
  }) {
    final peers = graph.nodes.map((node) => node.id).toSet();
    if (graph.nodes.isEmpty) {
      final id = '@empty:${parent ?? 'main'}:${insertion.branchId ?? ''}';
      entries[id] = CanvasEntry(id, null, insertion, peers);
      if (parent != null) links.add(CanvasLink(parent, id, label));
      return;
    }
    for (final node in graph.nodes) {
      entries[node.id.value] = CanvasEntry(
        node.id.value,
        node,
        BausteinInsertion(
          owner: insertion.owner,
          branchId: insertion.branchId,
          after: node.id,
        ),
        peers,
      );
    }
    for (final edge in graph.edges) {
      if (peers.contains(edge.from) && peers.contains(edge.to)) {
        links.add(
          CanvasLink(edge.from.value, edge.to.value, edge.conditionLabel),
        );
      }
    }
    if (parent != null) {
      final roots = graph.nodes.where(
        (node) => !graph.edges.any((edge) => edge.to == node.id),
      );
      for (final root in roots) {
        links.add(CanvasLink(parent, root.id.value, label));
      }
    }
    for (final node in graph.nodes) {
      switch (node.config) {
        case ConditionalNodeConfig(:final branches):
          for (final branch in branches) {
            _collect(
              branch.graph,
              BausteinInsertion(owner: node.id, branchId: branch.id),
              parent: node.id.value,
              label: branch.label,
            );
          }
        case ForEachNodeConfig(:final graph):
          _collect(
            graph,
            BausteinInsertion(owner: node.id),
            parent: node.id.value,
            label: 'Für jedes Element',
          );
        default:
          break;
      }
    }
  }

  void _arrange() {
    final remaining = entries.keys.toSet();
    final levels = <String, int>{};
    while (remaining.isNotEmpty) {
      final ready = remaining
          .where(
            (id) => !links.any(
              (edge) => edge.to == id && remaining.contains(edge.from),
            ),
          )
          .toList();
      // Imported cycles still need a finite, inspectable layout.
      if (ready.isEmpty) ready.add(remaining.first);
      for (final id in ready) {
        var level = 0;
        for (final edge in links.where((edge) => edge.to == id)) {
          if (levels.containsKey(edge.from)) {
            level = math.max(level, levels[edge.from]! + 1);
          }
        }
        levels[id] = level;
        remaining.remove(id);
      }
    }
    final rows = <int, List<String>>{};
    for (final entry in levels.entries) {
      (rows[entry.value] ??= []).add(entry.key);
    }
    final columns = rows.values.fold(
      1,
      (count, row) => math.max(count, row.length),
    );
    final width = math.max(720.0, columns * 390.0 + 100);
    for (final row in rows.entries) {
      final left = (width - ((row.value.length - 1) * 390 + cardWidth)) / 2;
      for (var index = 0; index < row.value.length; index++) {
        rectangles[row.value[index]] = Rect.fromLTWH(
          left + index * 390,
          90 + row.key * (nodeHeight + 100),
          cardWidth,
          nodeHeight,
        );
      }
    }
    size = Size(width, math.max(600, (rows.length + 1) * (nodeHeight + 100)));
  }
}
