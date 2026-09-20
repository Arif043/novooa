part of 'node_config.dart';

class ForEachNodeConfig extends NodeConfig {
  const ForEachNodeConfig({
    required this.itemsPointer,
    required this.graph,
    this.itemsTemplate = '',
  });

  final String itemsPointer;
  final WorkflowGraph graph;
  final String itemsTemplate;

  factory ForEachNodeConfig.initial() {
    return ForEachNodeConfig(itemsPointer: '', graph: WorkflowGraph.empty());
  }

  @override
  WorkflowPrimitive get primitive => .forEach;

  @override
  List<Object?> get props => [itemsPointer, graph, itemsTemplate];

  ForEachNodeConfig copyWith({
    String? itemsPointer,
    WorkflowGraph? graph,
    String? itemsTemplate,
  }) {
    return ForEachNodeConfig(
      itemsPointer: itemsPointer ?? this.itemsPointer,
      graph: graph ?? this.graph,
      itemsTemplate: itemsTemplate ?? this.itemsTemplate,
    );
  }
}
