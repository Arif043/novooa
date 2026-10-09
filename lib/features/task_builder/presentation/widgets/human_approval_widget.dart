import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

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
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_freigabe.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.instruction,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_was_soll_geprueft_werden.tr(),
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.reviewTemplate,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_zu_pruefender_wert.tr(),
              hintText: '{{baustein.value}}',
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(reviewTemplate: value),
            ),
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
