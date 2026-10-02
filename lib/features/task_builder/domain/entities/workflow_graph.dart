import 'package:equatable/equatable.dart';

import 'workflow_edge.dart';
import 'workflow_node.dart';

class WorkflowGraph extends Equatable {
  const WorkflowGraph({required this.nodes, required this.edges});

  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;

  @override
  List<Object?> get props => [nodes, edges];

  factory WorkflowGraph.empty() {
    return const WorkflowGraph(nodes: [], edges: []);
  }

  WorkflowNode? nodeOrNull(NodeId nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }

  /// Fügt [node] direkt nach [selectedNodeId] ein.
  ///
  /// Hatte [selectedNodeId] bereits Nachfolger (z.B. durch manuelles
  /// Verbinden mehrerer Ziele), werden diese zu Nachfolgern von [node]
  /// gespleißt, statt als zusätzliche parallele Zweige neben [node] stehen
  /// zu bleiben — [node] wird dadurch immer der eine direkte Nachfolger,
  /// nie einer von mehreren.
  WorkflowGraph addNode(WorkflowNode node, NodeId selectedNodeId) {
    if (nodeOrNull(node.id) != null) {
      throw ArgumentError.value(
        node.id,
        'node.id',
        'Knoten-ID ist bereits belegt.',
      );
    }
    if (nodes.isEmpty) {
      return copyWith(nodes: [...nodes, node]);
    }
    final newEdges = <WorkflowEdge>[
      for (final edge in edges)
        if (edge.from == selectedNodeId)
          WorkflowEdge(
            from: node.id,
            to: edge.to,
            conditionLabel: edge.conditionLabel,
          )
        else
          edge,
      WorkflowEdge(from: selectedNodeId, to: node.id),
    ];
    return copyWith(nodes: [...nodes, node], edges: newEdges);
  }

  List<WorkflowEdge> outgoingEdgesOf(NodeId nodeId) {
    return edges.where((edge) => edge.from == nodeId).toList(growable: false);
  }

  List<WorkflowEdge> incomingEdgesOf(NodeId nodeId) {
    return edges.where((edge) => edge.to == nodeId).toList(growable: false);
  }

  List<WorkflowNode> predecessorsOf(NodeId nodeId) {
    return incomingEdgesOf(nodeId)
        .map((edge) => nodes.firstWhere((node) => node.id == edge.from))
        .toList(growable: false);
  }

  List<WorkflowNode> successorsOf(NodeId nodeId) {
    return outgoingEdgesOf(nodeId)
        .map((edge) => nodes.firstWhere((node) => node.id == edge.to))
        .toList(growable: false);
  }

  WorkflowGraph updateEdgeCondition({
    required NodeId from,
    required NodeId to,
    required String? conditionLabel,
  }) {
    var changed = false;
    final newEdges = edges
        .map((edge) {
          if (edge.from == from && edge.to == to) {
            changed = true;
            return WorkflowEdge(
              from: edge.from,
              to: edge.to,
              conditionLabel: conditionLabel,
            );
          }
          return edge;
        })
        .toList(growable: false);
    if (!changed) return this;
    return copyWith(edges: newEdges);
  }

  WorkflowGraph addOutgoingCondition({
    required NodeId from,
    required NodeId to,
    String? conditionLabel,
  }) {
    final exists = edges.any((edge) => edge.from == from && edge.to == to);
    if (exists) {
      return updateEdgeCondition(
        from: from,
        to: to,
        conditionLabel: conditionLabel,
      );
    }
    return copyWith(
      edges: [
        ...edges,
        WorkflowEdge(from: from, to: to, conditionLabel: conditionLabel),
      ],
    );
  }

  /// Entfernt [nodeId] und spleißt dabei seine Vorgänger direkt mit seinen
  /// Nachfolgern zusammen (Kreuzprodukt aller ein-/ausgehenden Kanten),
  /// statt den Graphen in zwei unverbundene Komponenten zu zerlegen — ein
  /// Knoten in der Mitte einer Kette hat normalerweise genau einen
  /// Vorgänger/Nachfolger, wodurch daraus schlicht eine direkte Kante wird.
  WorkflowGraph removeNode(NodeId nodeId) {
    final remainingNodes = nodes
        .where((node) => node.id != nodeId)
        .toList(growable: false);
    final remainingEdges = edges
        .where((edge) => edge.from != nodeId && edge.to != nodeId)
        .toList();
    final predecessorIds = incomingEdgesOf(nodeId).map((edge) => edge.from);
    final successorIds = outgoingEdgesOf(nodeId).map((edge) => edge.to);
    for (final from in predecessorIds) {
      for (final to in successorIds) {
        final alreadyConnected = remainingEdges.any(
          (edge) => edge.from == from && edge.to == to,
        );
        if (from != to && !alreadyConnected) {
          remainingEdges.add(WorkflowEdge(from: from, to: to));
        }
      }
    }
    return copyWith(
      nodes: remainingNodes,
      edges: remainingEdges.toList(growable: false),
    );
  }

  WorkflowGraph swapNodes(NodeId sourceId, NodeId targetId) {
    if (sourceId == targetId) return this;
    final sourceIndex = nodes.indexWhere((node) => node.id == sourceId);
    final targetIndex = nodes.indexWhere((node) => node.id == targetId);
    if (sourceIndex < 0 || targetIndex < 0) return this;
    final swappedNodes = [...nodes];
    swappedNodes[sourceIndex] = nodes[targetIndex];
    swappedNodes[targetIndex] = nodes[sourceIndex];
    return copyWith(
      nodes: swappedNodes,
      edges: _swapEdgeEndpoints(sourceId, targetId),
    );
  }

  List<WorkflowEdge> _swapEdgeEndpoints(NodeId sourceId, NodeId targetId) {
    return edges
        .map((edge) {
          return WorkflowEdge(
            from: _swappedNodeId(edge.from, sourceId, targetId),
            to: _swappedNodeId(edge.to, sourceId, targetId),
            conditionLabel: edge.conditionLabel,
          );
        })
        .toList(growable: false);
  }

  NodeId _swappedNodeId(NodeId nodeId, NodeId sourceId, NodeId targetId) {
    if (nodeId == sourceId) return targetId;
    if (nodeId == targetId) return sourceId;
    return nodeId;
  }

  WorkflowGraph copyWith({
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
  }) {
    return WorkflowGraph(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }
}
