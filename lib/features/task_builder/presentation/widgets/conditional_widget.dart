import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({
    super.key,
    required this.nodeConfig,
    required this.onBranchSelected,
    required this.onValueTemplateChanged,
  });

  final ConditionalNodeConfig nodeConfig;
  final ValueChanged<ConditionalBranch> onBranchSelected;
  final ValueChanged<String> onValueTemplateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        children: [
          Text('Wenn', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: nodeConfig.valueTemplate,
            decoration: const InputDecoration(
              labelText: 'Wert',
              hintText: '{{baustein.value}}',
            ),
            onChanged: onValueTemplateChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
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
                    onBranchSelected(branch);
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
