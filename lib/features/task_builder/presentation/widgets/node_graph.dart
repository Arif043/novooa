import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_pager.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/deletable_node_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/human_approval_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/iterative_refinement_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_drag_handle.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_email_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_file_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/send_message_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/string_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_widget.dart';

class NodeGraph extends StatefulWidget {
  const NodeGraph({super.key, required this.nodes});

  final List<WorkflowNode> nodes;

  @override
  State<NodeGraph> createState() => _NodeGraphState();
}

class _NodeGraphState extends State<NodeGraph> {
  NodeId? _draggingNodeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.nodes.map(
          (node) => _SwappableNode(
            node: node,
            isSource: _draggingNodeId == node.id,
            onDragStarted: () => _setDraggingNode(node.id),
            onDragEnded: _clearDraggingNode,
            child: _nodeWidget(node),
          ),
        ),
        NodePlaceholder(onAccept: (value) {}),
      ],
    );
  }

  Widget _nodeWidget(WorkflowNode node) {
    final child = switch (node.config.primitive) {
      .stringInput => StringInputWidget(node: node),
      .script => ScriptWidget(node: node),
      .prompt => PromptWidget(node: node),
      .conditional => ConditionalPager(key: ValueKey(node.id), node: node),
      .iterativeRefinement => IterativeRefinementWidget(node: node),
      .writeFile => WriteFileWidget(node: node),
      .readFile => ReadFileWidget(node: node),
      .readEmail || .readChannelEvent => ReadEventWidget(node: node),
      .sendChannelMessage => SendMessageWidget(node: node),
      .humanApproval => HumanApprovalWidget(node: node),
      _ => const SizedBox.shrink(),
    };
    return DeletableNodeWidget(node: node, child: child);
  }

  void _setDraggingNode(NodeId nodeId) {
    setState(() => _draggingNodeId = nodeId);
  }

  void _clearDraggingNode() {
    if (_draggingNodeId == null) return;
    setState(() => _draggingNodeId = null);
  }
}

class _SwappableNode extends StatelessWidget {
  const _SwappableNode({
    required this.node,
    required this.child,
    required this.isSource,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  static const animationDuration = Duration(milliseconds: 220);

  final WorkflowNode node;
  final Widget child;
  final bool isSource;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    return DragTarget<NodeId>(
      onWillAcceptWithDetails: (details) => details.data != node.id,
      onAcceptWithDetails: (details) {
        context.read<TaskBuilderCubit>().swapNodes(details.data, node.id);
      },
      builder: (context, candidates, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            decoration: _dropDecoration(context, candidates.isNotEmpty),
            child: Stack(
              children: [
                _AnimatedNodeSlot(node: node, isSource: isSource, child: child),
                Positioned(
                  top: AppSpacing.xs,
                  left: AppSpacing.xs,
                  child: NodeDragHandle(node: node, onDragStarted: onDragStarted, onDragEnded: onDragEnded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Decoration _dropDecoration(BuildContext context, bool isTargeted) {
    if (!isTargeted) return const BoxDecoration();
    final color = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      border: Border.all(color: color.withValues(alpha: 0.65), width: 2),
      borderRadius: BorderRadius.circular(8),
    );
  }
}

class _AnimatedNodeSlot extends StatelessWidget {
  const _AnimatedNodeSlot({required this.node, required this.child, required this.isSource});

  final WorkflowNode node;
  final Widget child;
  final bool isSource;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _SwappableNode.animationDuration,
      curve: Curves.easeOutCubic,
      decoration: _sourceDecoration(context),
      child: AnimatedSwitcher(
        duration: _SwappableNode.animationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: _transition,
        child: KeyedSubtree(key: ValueKey(node.id), child: child),
      ),
    );
  }

  Decoration _sourceDecoration(BuildContext context) {
    if (!isSource) return const BoxDecoration();
    final color = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 22, spreadRadius: 2)],
    );
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
