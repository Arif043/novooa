import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/conditional_controller_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';

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
      .prompt => PromptWidget(node: node),
      .conditional => BlocProvider(
        key: ValueKey(node.config),
        create: (_) => serviceLocator<ConditionalControllerCubit>()..load(node.config as ConditionalNodeConfig),
        child: LayoutBuilder(
          builder: (_, constraints) => BlocBuilder<ConditionalControllerCubit, ConditionalControllerState>(
            builder: (context, state) {
              if (state.selectedBranch != null) {
                return BranchWidget(branch: state.selectedBranch!, conditionalNodeId: node.id);
              }
              return ConditionalWidget(nodeConfig: state.nodeConfig!);
            },
          ),
        ),
      ),
      _ => SizedBox.shrink(),
    };
  }
}
