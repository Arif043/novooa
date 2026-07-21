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
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_email_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_file_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/send_message_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/string_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_widget.dart';

class NodeGraphItem extends StatelessWidget {
  const NodeGraphItem({
    super.key,
    required this.node,
    required this.dragSourceNodeIds,
    required this.isSource,
    required this.isDragActive,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  static const animationDuration = Duration(milliseconds: 500);

  final WorkflowNode node;
  final Set<NodeId> dragSourceNodeIds;
  final bool isSource;
  final bool isDragActive;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    return DragTarget<NodeId>(
      key: ValueKey('node-target-${node.id.value}'),
      onWillAcceptWithDetails: _accepts,
      onAcceptWithDetails: (details) {
        context.read<TaskBuilderCubit>().swapNodes(details.data, node.id);
      },
      builder: _buildTarget,
    );
  }

  bool _accepts(DragTargetDetails<NodeId> details) {
    return details.data != node.id && dragSourceNodeIds.contains(details.data);
  }

  Widget _buildTarget(
    BuildContext context,
    List<NodeId?> candidates,
    List<dynamic> rejected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedContainer(
        duration: animationDuration,
        clipBehavior: Clip.none,
        curve: Curves.easeOutCubic,
        decoration: _dropDecoration(context, candidates.isNotEmpty),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        _nodeWidget(),
        Positioned(
          top: AppSpacing.xs,
          left: AppSpacing.xs,
          child: NodeDragHandle(
            node: node,
            isDragging: isDragActive,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
          ),
        ),
      ],
    );
  }

  Decoration _dropDecoration(BuildContext context, bool isTargeted) {
    final color = Theme.of(context).colorScheme.primary;
    final highlighted = isTargeted || isSource;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: highlighted ? 0.24 : 0),
          blurRadius: highlighted ? AppSpacing.lg : 0,
          spreadRadius: highlighted ? AppSpacing.xs : 0,
        ),
      ],
    );
  }

  Widget _nodeWidget() {
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
    return FocusScope(
      key: ValueKey('node-focus-${node.id.value}'),
      canRequestFocus: !isDragActive,
      descendantsAreFocusable: !isDragActive,
      child: IgnorePointer(
        key: ValueKey('node-input-${node.id.value}'),
        ignoring: isDragActive,
        child: DeletableNodeWidget(node: node, child: child),
      ),
    );
  }
}
