enum WorkflowPrimitive {
  prompt,
  conditionalFlow,
  iterativeRefinement,
  toolCall,
  humanApproval,
  validation,
}

class NodeId {
  const NodeId(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is NodeId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class WorkflowNode {
  const WorkflowNode({
    required this.id,
    required this.primitive,
    required this.title,
    required this.description,
  });

  final NodeId id;
  final WorkflowPrimitive primitive;
  final String title;
  final String description;

  WorkflowNode copyWith({
    WorkflowPrimitive? primitive,
    String? title,
    String? description,
  }) {
    return WorkflowNode(
      id: id,
      primitive: primitive ?? this.primitive,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}
