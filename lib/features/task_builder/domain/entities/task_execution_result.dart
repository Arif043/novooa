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
    this.outputs = const {},
    this.selectedNodeId,
    this.message,
  });

  final NodeId nodeId;
  final WorkflowPrimitive primitive;
  final NodeExecutionStatus status;
  final Map<String, NodeOutputValue> outputs;
  final NodeId? selectedNodeId;
  final String? message;
}

enum NodeOutputType {
  string,
  datetime,
  number,
  boolean,
  json,
  file,
  media;

  static NodeOutputType fromName(String name) {
    return NodeOutputType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => NodeOutputType.json,
    );
  }
}

class NodeOutputValue {
  const NodeOutputValue({required this.type, required this.value});

  final NodeOutputType type;
  final Object? value;
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
