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
  const CanvasEntry(
    this.id,
    this.node,
    this.insertion,
    this.peers, {
    this.continuationLabel,
  });
  final String id;
  final WorkflowNode? node;
  final BausteinInsertion insertion;
  final Set<NodeId> peers;
  final String? continuationLabel;
}

class CanvasLink {
  const CanvasLink(this.from, this.to, [this.label, this.isReturn = false]);
  final String from;
  final String to;
  final String? label;
  final bool isReturn;
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

  List<String> _collect(
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
      return [id];
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
          CanvasLink(
            _exitId(graph.nodeOrNull(edge.from)!),
            edge.to.value,
            edge.conditionLabel,
          ),
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
      final branchEnds = <String>[];
      switch (node.config) {
        case ConditionalNodeConfig(:final branches):
          for (final branch in branches) {
            branchEnds.addAll(
              _collect(
                branch.graph,
                BausteinInsertion(owner: node.id, branchId: branch.id),
                parent: node.id.value,
                label: branch.label,
              ),
            );
          }
        case ForEachNodeConfig(:final graph):
          branchEnds.addAll(
            _collect(
              graph,
              BausteinInsertion(owner: node.id),
              parent: node.id.value,
              label: 'Für jedes Element',
            ),
          );
        default:
          break;
      }
      if (_exitId(node) != node.id.value) {
        final id = _exitId(node);
        entries[id] = CanvasEntry(
          id,
          null,
          entries[node.id.value]!.insertion,
          peers,
          continuationLabel: node.config is ConditionalNodeConfig
              ? 'Nach der Bedingung'
              : 'Nach der Schleife',
        );
        for (final end in branchEnds.isEmpty ? [node.id.value] : branchEnds) {
          links.add(CanvasLink(end, id, null, true));
        }
      }
    }
    final ends = <String>[];
    for (final node in graph.nodes) {
      if (graph.edges.any(
        (edge) => edge.from == node.id && peers.contains(edge.to),
      )) {
        continue;
      }
      if (_exitId(node) != node.id.value) {
        ends.add(_exitId(node));
      } else {
        final id = '@append:${node.id.value}';
        entries[id] = CanvasEntry(
          id,
          null,
          entries[node.id.value]!.insertion,
          peers,
        );
        links.add(CanvasLink(node.id.value, id));
        ends.add(id);
      }
    }
    return ends;
  }

  String _exitId(WorkflowNode node) => switch (node.config) {
    ConditionalNodeConfig() ||
    ForEachNodeConfig() => '@continue:${node.id.value}',
    _ => node.id.value,
  };

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
