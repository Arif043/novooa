import 'package:flutter/material.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph_item.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_position_transition.dart';
import 'workflow_editor_scope.dart';
import 'workflow_canvas.dart';
import '../cubits/workflow_primitive_labels.dart';
import 'baustein_palette.dart';

class NodeGraph extends StatefulWidget {
  const NodeGraph({super.key, required this.nodes, this.onPrimitiveAccepted});

  final List<WorkflowNode> nodes;
  final ValueChanged<WorkflowPrimitive>? onPrimitiveAccepted;

  @override
  State<NodeGraph> createState() => _NodeGraphState();
}

class _NodeGraphState extends State<NodeGraph> {
  final Map<NodeId, GlobalKey> _itemKeys = {};
  Map<NodeId, double> _motionOffsets = {};
  NodeId? _draggingNodeId;

  @override
  void didUpdateWidget(NodeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motionOffsets = _swapOffsets(oldWidget.nodes, widget.nodes);
    if (_motionOffsets.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _clearOffsets());
  }

  @override
  Widget build(BuildContext context) {
    final editor = WorkflowEditorScope.maybeOf(context);
    if (editor != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final node in widget.nodes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: MediaQuery.textScalerOf(context).scale(120),
                child: CompactWorkflowNode(
                  node: node,
                  selected: false,
                  peers: widget.nodes.map((node) => node.id).toSet(),
                  onTap: () => editor.onSelect(node),
                ),
              ),
            ),
          PopupMenuButton<WorkflowPrimitive>(
            tooltip: 'Baustein hinzufügen',
            onSelected: widget.onPrimitiveAccepted,
            itemBuilder: (_) => [
              for (final primitive
                  in bausteinGroups.values
                      .expand((group) => group)
                      .map((choice) => choice.primitive)
                      .toSet())
                PopupMenuItem(value: primitive, child: Text(primitive.label)),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Baustein hinzufügen'),
                ],
              ),
            ),
          ),
        ],
      );
    }
    _removeObsoleteKeys();
    final graphNodeIds = widget.nodes.map((node) => node.id).toSet();
    return MouseRegion(
      cursor: _draggingNodeId == null
          ? MouseCursor.defer
          : SystemMouseCursors.grabbing,
      child: Column(
        children: [
          ...widget.nodes.map((node) => _buildNode(node, graphNodeIds)),
          NodePlaceholder(onAccept: widget.onPrimitiveAccepted ?? _ignore),
        ],
      ),
    );
  }

  Widget _buildNode(WorkflowNode node, Set<NodeId> graphNodeIds) {
    return NodePositionTransition(
      key: ValueKey(node.id),
      offsetY: _motionOffsets[node.id] ?? 0,
      child: KeyedSubtree(
        key: _itemKeys.putIfAbsent(node.id, GlobalKey.new),
        child: NodeGraphItem(
          key: ValueKey('node-content-${node.id.value}'),
          node: node,
          dragSourceNodeIds: graphNodeIds,
          isSource: _draggingNodeId == node.id,
          isDragActive: _draggingNodeId != null,
          onDragStarted: () => _setDraggingNode(node.id),
          onDragEnded: _clearDraggingNode,
        ),
      ),
    );
  }

  Map<NodeId, double> _swapOffsets(
    List<WorkflowNode> oldNodes,
    List<WorkflowNode> newNodes,
  ) {
    if (!_isSwap(oldNodes, newNodes)) return {};
    final oldTops = _topOffsets(oldNodes);
    final newTops = _topOffsets(newNodes);
    return {
      for (final node in newNodes)
        node.id: (oldTops[node.id] ?? 0) - (newTops[node.id] ?? 0),
    };
  }

  bool _isSwap(List<WorkflowNode> oldNodes, List<WorkflowNode> newNodes) {
    if (oldNodes.length != newNodes.length) return false;
    final changed = <int>[];
    for (var index = 0; index < newNodes.length; index++) {
      if (oldNodes[index].id != newNodes[index].id) changed.add(index);
    }
    if (changed.length != 2) return false;
    final first = changed.first;
    final second = changed.last;
    return oldNodes[first].id == newNodes[second].id &&
        oldNodes[second].id == newNodes[first].id;
  }

  Map<NodeId, double> _topOffsets(List<WorkflowNode> nodes) {
    final offsets = <NodeId, double>{};
    var top = 0.0;
    for (final node in nodes) {
      offsets[node.id] = top;
      top += _itemHeight(node.id);
    }
    return offsets;
  }

  double _itemHeight(NodeId nodeId) {
    final context = _itemKeys[nodeId]?.currentContext;
    final renderBox = context?.findRenderObject();
    return renderBox is RenderBox ? renderBox.size.height : 0;
  }

  void _removeObsoleteKeys() {
    final nodeIds = widget.nodes.map((node) => node.id).toSet();
    _itemKeys.removeWhere((nodeId, _) => !nodeIds.contains(nodeId));
  }

  void _clearOffsets() {
    if (!mounted || _motionOffsets.isEmpty) return;
    setState(() => _motionOffsets = {});
  }

  void _setDraggingNode(NodeId nodeId) {
    FocusScope.of(context).unfocus();
    setState(() => _draggingNodeId = nodeId);
  }

  void _clearDraggingNode() {
    if (_draggingNodeId == null) return;
    setState(() => _draggingNodeId = null);
  }

  static void _ignore(WorkflowPrimitive primitive) {}
}
