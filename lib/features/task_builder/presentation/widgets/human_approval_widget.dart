import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class HumanApprovalWidget extends StatelessWidget {
  const HumanApprovalWidget({super.key, required this.node});

  final WorkflowNode node;

  HumanApprovalNodeConfig get _config {
    return node.config as HumanApprovalNodeConfig;
  }

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
          Text('Freigabe', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _config.instruction,
            decoration: const InputDecoration(
              hintText: 'Was soll geprüft werden?',
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<HumanApprovalReviewScope>(
            initialValue: _config.reviewScope,
            decoration: const InputDecoration(labelText: 'Anzuzeigende Daten'),
            items: const [
              DropdownMenuItem(
                value: HumanApprovalReviewScope.currentInput,
                child: Text('Aktueller Input'),
              ),
              DropdownMenuItem(
                value: HumanApprovalReviewScope.executionTrace,
                child: Text('Bisherige Ergebnisse'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              _update(context, (config) => config.copyWith(reviewScope: value));
            },
          ),
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    HumanApprovalNodeConfig Function(HumanApprovalNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updateHumanApproval(node.id, update);
  }
}
