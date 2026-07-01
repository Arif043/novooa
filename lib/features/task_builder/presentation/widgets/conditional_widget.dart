import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/conditional_controller_cubit.dart';

class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({
    super.key,
    required this.nodeConfig,
    this.onBranchSelected,
  });

  final ConditionalNodeConfig nodeConfig;
  final ValueChanged<ConditionalBranch>? onBranchSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        children: [
          Text('Wenn', style: SyscatTheme.taskBody),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (
                int choiceIndex = 0;
                choiceIndex < nodeConfig.choices.length;
                choiceIndex++
              )
                ActionChip(
                  label: Text(_buildBranchLabel(choiceIndex)),
                  shape: LinearBorder(),
                  backgroundColor: SyscatTheme.primaryOrange,
                  onPressed: () {
                    final branch = nodeConfig.branches[choiceIndex];
                    final select = onBranchSelected;
                    if (select != null) {
                      select(branch);
                      return;
                    }
                    context.read<ConditionalControllerCubit>().selectBranch(
                      branch,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildBranchLabel(int choiceIndex) {
    final choices = nodeConfig.choices;
    if (choices[choiceIndex].isNotEmpty) {
      return choices[choiceIndex];
    }
    return 'Antwort ${choiceIndex + 1}';
  }
}
