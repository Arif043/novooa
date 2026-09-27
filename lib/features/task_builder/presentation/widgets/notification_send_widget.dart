import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class NotificationSendWidget extends StatelessWidget {
  const NotificationSendWidget({super.key, required this.node});

  final WorkflowNode node;

  NotificationSendNodeConfig get _config {
    return node.config as NotificationSendNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Push-Benachrichtigung', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.title,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: const InputDecoration(
              labelText: 'Titel (optional)',
              hintText: 'Benachrichtigung von novooa',
            ),
            onChanged: (value) =>
                _update(context, (config) => config.copyWith(title: value)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.message,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Text',
              hintText: '{{baustein.value}}',
            ),
            onChanged: (value) =>
                _update(context, (config) => config.copyWith(message: value)),
          ),
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    NotificationSendNodeConfig Function(NotificationSendNodeConfig config)
    update,
  ) {
    context.read<TaskBuilderCubit>().updateNotificationSend(node.id, update);
  }
}
