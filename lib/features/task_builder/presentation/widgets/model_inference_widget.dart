import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class ModelInferenceWidget extends StatelessWidget {
  const ModelInferenceWidget({super.key, required this.node});

  final WorkflowNode node;

  ModelInferenceNodeConfig get _config =>
      node.config as ModelInferenceNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modell ausführen', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _config.modelId,
            decoration: const InputDecoration(hintText: 'Modell-ID'),
            onChanged: (modelId) => context
                .read<TaskBuilderCubit>()
                .updateModelInference(node.id, modelId),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nimmt Werte gemäß Modellvertrag vom vorherigen Baustein entgegen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
