import 'workflow_node.dart';

enum NodeExecutionStatus {
  executed,
  skipped,
  waitingForApproval;

  static NodeExecutionStatus fromName(String name) {
    return switch (name) {
      'executed' => NodeExecutionStatus.executed,
      'skipped' => NodeExecutionStatus.skipped,
      'waitingForApproval' => NodeExecutionStatus.waitingForApproval,
      _ => NodeExecutionStatus.skipped,
    };
  }
}

class NodeExecutionResult {
  const NodeExecutionResult({
    required this.nodeId,
    required this.primitive,
    required this.status,
    required this.output,
    this.selectedNodeId,
    this.message,
  });

  final NodeId nodeId;
  final WorkflowPrimitive primitive;
  final NodeExecutionStatus status;
  final String output;
  final NodeId? selectedNodeId;
  final String? message;
}

class TaskExecutionResult {
  const TaskExecutionResult({
    required this.taskId,
    required this.finalOutput,
    required this.nodeResults,
  });

  final String taskId;
  final String finalOutput;
  final List<NodeExecutionResult> nodeResults;
}
