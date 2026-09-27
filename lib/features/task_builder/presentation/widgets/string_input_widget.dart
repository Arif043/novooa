import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

class StringInputWidget extends StatefulWidget {
  const StringInputWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<StringInputWidget> createState() => _StringInputWidgetState();
}

class _StringInputWidgetState extends State<StringInputWidget> {
  StringInputNodeConfig get _config {
    return widget.node.config as StringInputNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    final task = context.select<TaskBuilderCubit, TaskBuilderLoaded?>(
      (cubit) => switch (cubit.state) {
        TaskBuilderLoaded() => cubit.state as TaskBuilderLoaded,
        _ => null,
      },
    );
    final suggestions = task == null
        ? const <TemplateExpressionSuggestion>[]
        : templateExpressionSuggestions(
            graph: task.editingTask.graph,
            targetNodeId: widget.node.id,
          );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Texteingabe', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TemplateExpressionTextField(
            value: _config.value,
            suggestions: suggestions,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Text eingeben'),
            onChanged: _updateValue,
          ),
        ],
      ),
    );
  }

  void _updateValue(String value) {
    context.read<TaskBuilderCubit>().updateStringInputValue(
      widget.node.id,
      value,
    );
  }
}
