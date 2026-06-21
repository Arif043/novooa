import 'workflow_node.dart';

class WorkflowEdge {
  const WorkflowEdge({
    required this.from,
    required this.to,
    this.conditionLabel,
  });

  final NodeId from;
  final NodeId to;
  final String? conditionLabel;
}
