import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';

class BranchWidget extends StatelessWidget {
  final ConditionalBranch branch;
  final NodeId conditionalNodeId;
  final VoidCallback onBack;

  const BranchWidget({
    super.key,
    required this.branch,
    required this.conditionalNodeId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: .min,
              children: [
                CupertinoNavigationBarBackButton(onPressed: onBack),
                Text('Fall:  ', style: SyscatTheme.taskBody),
                Text(
                  branch.label,
                  style: SyscatTheme.taskBody.copyWith(fontWeight: .w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NodeGraph(
              nodes: branch.graph.nodes,
              onPrimitiveAccepted: (primitive) =>
                  context.read<TaskBuilderCubit>().addNodeToBranch(
                    conditionalNodeId: conditionalNodeId,
                    branchId: branch.id,
                    primitive: primitive,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
