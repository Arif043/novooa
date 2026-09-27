import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

part 'model_input_parameter_editor.dart';
part 'model_input_parameter_controls.dart';

class ModelSettingConfiguration extends StatelessWidget {
  const ModelSettingConfiguration({
    super.key,
    required this.nodeId,
    required this.settings,
    required this.values,
  });

  final NodeId nodeId;
  final List<ModelManifestSetting> settings;
  final List<ModelInferenceSetting> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modelleinstellungen',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final parameter in settings) ...[
          _ParameterControl(
            nodeId: nodeId,
            parameter: parameter,
            value: _valueFor(parameter),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  String _valueFor(ModelManifestSetting parameter) {
    for (final value in values) {
      if (value.name == parameter.name) return value.valueTemplate;
    }
    return '${parameter.control.initialValue()}';
  }
}
