import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'baustein_icon_avatar.dart';
import 'baustein_swap_handle.dart';
import 'compact_node_card.dart';

/// Baustein auf der Leinwand. Über sein Icon lässt er sich auf einen
/// Geschwister-Baustein ([peers]) ziehen und mit ihm tauschen.
class CompactWorkflowNode extends StatefulWidget {
  const CompactWorkflowNode({
    super.key,
    required this.node,
    required this.selected,
    required this.onTap,
    this.targeted = false,
    this.peers = const {},
  });

  final WorkflowNode node;
  final bool selected;
  final bool targeted;
  final VoidCallback onTap;
  final Set<NodeId> peers;

  @override
  State<CompactWorkflowNode> createState() => _CompactWorkflowNodeState();
}

class _CompactWorkflowNodeState extends State<CompactWorkflowNode> {
  static const _draggedOpacity = .38;

  final _cardKey = GlobalKey();
  bool _isDragged = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<NodeId>(
      onWillAcceptWithDetails: (details) =>
          details.data != widget.node.id && widget.peers.contains(details.data),
      onAcceptWithDetails: (details) => context
          .read<TaskBuilderCubit>()
          .swapNodes(details.data, widget.node.id),
      builder: (context, candidates, _) => Opacity(
        opacity: _isDragged ? _draggedOpacity : 1,
        child: CompactNodeCard(
          key: _cardKey,
          node: widget.node,
          selected: widget.selected,
          highlighted: widget.targeted || candidates.isNotEmpty,
          onTap: widget.onTap,
          leading: _swapHandle(),
        ),
      ),
    );
  }

  Widget _swapHandle() {
    return BausteinSwapHandle(
      node: widget.node,
      sourceKey: _cardKey,
      feedback: CompactNodeCard(
        node: widget.node,
        selected: true,
        elevation: 8,
        leading: BausteinIconAvatar(primitive: widget.node.config.primitive),
      ),
      onDragStarted: () => setState(() => _isDragged = true),
      onDragEnded: () {
        if (mounted) setState(() => _isDragged = false);
      },
    );
  }
}
