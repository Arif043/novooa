import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'prompt_resource_selection.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class IterativeRefinementWidget extends StatefulWidget {
  const IterativeRefinementWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<IterativeRefinementWidget> createState() =>
      _IterativeRefinementWidgetState();
}

class _IterativeRefinementWidgetState extends State<IterativeRefinementWidget> {
  IterativeRefinementNodeConfig get _config {
    return widget.node.config as IterativeRefinementNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ui_iterative_verfeinerung.tr(),
            style: SyscatTheme.taskBody,
          ),
          const SizedBox(height: AppSpacing.md),
          TemplateExpressionTextField(
            value: _config.draftTemplate,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_entwurf.tr(),
              hintText: '{{baustein.value}}',
            ),
            onChanged: _updateDraft,
          ),
          const SizedBox(height: AppSpacing.md),
          TemplateExpressionTextField(
            value: _config.optimizerPrompt,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_optimierer_prompt.tr(),
            ),
            onChanged: _updateOptimizer,
          ),
          const SizedBox(height: AppSpacing.md),
          TemplateExpressionTextField(
            value: _config.critiquePrompt,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: LocaleKeys.ui_kritik.tr()),
            onChanged: _updateCritique,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LocaleKeys.ui_maximale_iterationen.tr(),
            style: SyscatTheme.taskBodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _config.maxIterations,
            backgroundColor: SyscatTheme.surfaceContainer,
            thumbColor: SyscatTheme.glassSurface,
            children: {
              for (var value = 1; value <= 5; value++) value: Text('$value'),
            },
            onValueChanged: _updateMaxIterations,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LocaleKeys.ui_verfeinert_den_angegebenen_entwurf.tr(),
            style: SyscatTheme.taskBodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          PromptResourceSelection(
            employeeId: _config.employeeId,
            skillAttachments: _config.skillAttachments,
            onAttachSkill: _attachSkill,
            onDetachSkill: _detachSkill,
            onAssignEmployee: _assignEmployee,
            onUnassignEmployee: _unassignEmployee,
          ),
        ],
      ),
    );
  }

  void _attachSkill(SkillAttachment attachment) {
    context.read<TaskBuilderCubit>().attachNodeSkill(
      nodeId: widget.node.id,
      attachment: attachment,
    );
  }

  void _detachSkill(String attachmentId) {
    context.read<TaskBuilderCubit>().detachNodeSkill(
      nodeId: widget.node.id,
      attachmentId: attachmentId,
    );
  }

  void _assignEmployee(String employeeId) {
    context.read<TaskBuilderCubit>().assignNodeEmployee(
      nodeId: widget.node.id,
      employeeId: employeeId,
    );
  }

  void _unassignEmployee() {
    context.read<TaskBuilderCubit>().unassignNodeEmployee(
      nodeId: widget.node.id,
    );
  }

  void _updateCritique(String value) {
    context.read<TaskBuilderCubit>().updateIterativeCritique(
      widget.node.id,
      value,
    );
  }

  void _updateDraft(String value) {
    context.read<TaskBuilderCubit>().updateIterativeDraft(
      widget.node.id,
      value,
    );
  }

  void _updateOptimizer(String value) {
    context.read<TaskBuilderCubit>().updateIterativeOptimizer(
      widget.node.id,
      value,
    );
  }

  void _updateMaxIterations(int? value) {
    if (value == null) return;
    context.read<TaskBuilderCubit>().updateIterativeMaxIterations(
      widget.node.id,
      value,
    );
  }
}
