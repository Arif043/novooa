import 'package:flutter/material.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_pager.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/human_approval_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/iterative_refinement_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/string_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_widget.dart';

class NodeGraph extends StatefulWidget {
  const NodeGraph({super.key, required this.nodes});

  final List<WorkflowNode> nodes;

  @override
  State<NodeGraph> createState() => _NodeGraphState();
}

class _NodeGraphState extends State<NodeGraph> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.nodes.map(_nodeWidgetOrNull),
        // NodePlaceholder(onAccept: (value) => context.read<TaskBuilderCubit>().addNodeToMainGraph(value)),
      ],
    );
  }

  Widget _nodeWidgetOrNull(WorkflowNode node) {
    return switch (node.config.primitive) {
      .stringInput => StringInputWidget(node: node),
      .script => ScriptWidget(node: node),
      .prompt => PromptWidget(node: node),
      .conditional => ConditionalPager(key: ValueKey(node.id), node: node),
      .iterativeRefinement => IterativeRefinementWidget(node: node),
      .writeFile => WriteFileWidget(node: node),
      .humanApproval => HumanApprovalWidget(node: node),
      _ => SizedBox.shrink(),
    };
  }
}
