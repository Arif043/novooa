import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/human_approval_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/iterative_refinement_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/string_input_widget.dart';

class BranchWidget extends StatelessWidget {
  final ConditionalBranch branch;
  final NodeId conditionalNodeId;
  final VoidCallback onBack;
  final void Function(WorkflowNode node, ConditionalBranch branch)
  onBranchSelected;

  const BranchWidget({
    super.key,
    required this.branch,
    required this.conditionalNodeId,
    required this.onBack,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: .min,
            children: [
              CupertinoNavigationBarBackButton(onPressed: onBack),
              Text('Fall:  ', style: SyscatTheme.taskBody),
              // const SizedBox(width: AppSpacing.md),
              Text(
                branch.label,
                style: SyscatTheme.taskBody.copyWith(fontWeight: .w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final node in branch.graph.nodes) _branchNode(node),
          NodePlaceholder(
            onAccept: (primitive) {
              context.read<TaskBuilderCubit>().addNodeToBranch(
                conditionalNodeId: conditionalNodeId,
                branchId: branch.id,
                primitive: primitive,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _branchNode(WorkflowNode node) {
    return switch (node.config.primitive) {
      .stringInput => StringInputWidget(node: node),
      .prompt => PromptWidget(node: node),
      .script => ScriptWidget(node: node),
      .conditional => ConditionalWidget(
        nodeConfig: node.config as ConditionalNodeConfig,
        onBranchSelected: (branch) {
          onBranchSelected(node, branch);
        },
      ),
      .iterativeRefinement => IterativeRefinementWidget(node: node),
      .humanApproval => HumanApprovalWidget(node: node),
      _ => const SizedBox.shrink(),
    };
  }
}
