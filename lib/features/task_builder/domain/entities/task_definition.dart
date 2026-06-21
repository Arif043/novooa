import 'workflow_edge.dart';
import 'workflow_node.dart';

class TaskDefinition {
  const TaskDefinition({
    required this.id,
    required this.title,
    required this.objective,
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
  });

  final String id;
  final String title;
  final String objective;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final NodeId selectedNodeId;

  WorkflowNode get selectedNode {
    return nodes.firstWhere((node) => node.id == selectedNodeId);
  }

  TaskDefinition selectNode(NodeId nodeId) {
    return copyWith(selectedNodeId: nodeId);
  }

  TaskDefinition addNode(WorkflowNode node) {
    return copyWith(
      nodes: [...nodes, node],
      edges: [
        ...edges,
        WorkflowEdge(from: selectedNodeId, to: node.id),
      ],
      selectedNodeId: node.id,
    );
  }

  TaskDefinition copyWith({
    String? title,
    String? objective,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    NodeId? selectedNodeId,
  }) {
    return TaskDefinition(
      id: id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
    );
  }
}
