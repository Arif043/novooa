part of 'node_config.dart';

class ForEachNodeConfig extends NodeConfig {
  const ForEachNodeConfig({required this.itemsPointer, required this.graph});

  final String itemsPointer;
  final WorkflowGraph graph;

  factory ForEachNodeConfig.initial() {
    return ForEachNodeConfig(itemsPointer: '', graph: WorkflowGraph.empty());
  }

  @override
  WorkflowPrimitive get primitive => .forEach;

  @override
  List<Object?> get props => [itemsPointer, graph];

  ForEachNodeConfig copyWith({String? itemsPointer, WorkflowGraph? graph}) {
    return ForEachNodeConfig(
      itemsPointer: itemsPointer ?? this.itemsPointer,
      graph: graph ?? this.graph,
    );
  }
}
