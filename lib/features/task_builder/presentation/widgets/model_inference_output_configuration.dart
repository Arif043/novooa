import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';

/// Zeigt, welche Workflow-Ausgaben das Modell liefert. Einstellbare Werte
/// stehen als Settings unter den Modelleinstellungen.
class ModelInferenceOutputConfiguration extends StatelessWidget {
  const ModelInferenceOutputConfiguration({super.key, required this.outputs});

  final List<ModelManifestOutput> outputs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Modellausgabe', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final output in outputs)
          _WorkflowOutputDescription(output: output),
      ],
    );
  }
}

class _WorkflowOutputDescription extends StatelessWidget {
  const _WorkflowOutputDescription({required this.output});

  final ModelManifestOutput output;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        '${output.workflowName} - ${output.workflowTypeLabel}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
