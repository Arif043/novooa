import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../../domain/entities/node_config.dart';
import '../../../domain/entities/workflow_node.dart';
import '../../agent/node_field_key.dart';
import '../../agent/task_builder_cursor_targets.dart';
import '../../cubits/task_builder_cubit.dart';
import '../field_helper_text.dart';
import '../node_file_attachment_section.dart';
import '../node_knowledge_attachment_section.dart';
import '../node_language_model_field.dart';
import '../structured_output_fields_editor.dart';
import '../template_expression_scope.dart';
import '../template_expression_text_field.dart';
import 'team_member_section.dart';
import 'teamwork_review_section.dart';

/// Baustein „Teamarbeit“: Anweisung und Modell des Orchestrators, das Team,
/// die Prüfung, die Felder des Ergebnisses und die Anhänge.
class TeamworkWidget extends StatelessWidget {
  const TeamworkWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as TeamworkNodeConfig;
    final cubit = context.read<TaskBuilderCubit>();
    const gap = Divider(height: AppSpacing.lg * 2);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Orchestrator(node: node, config: config),
          gap,
          TeamMemberSection(
            config: config,
            onAdd: (employeeId) => cubit.addTeamMember(node.id, employeeId),
            onChanged: (member) => cubit.updateTeamMember(node.id, member),
            onRemove: (employeeId) =>
                cubit.removeTeamMember(node.id, employeeId),
          ),
          gap,
          TeamworkReviewSection(
            review: config.review,
            onChanged: (review) => cubit.updateTeamworkReview(node.id, review),
          ),
          gap,
          _Result(node: node, config: config),
          gap,
          NodeFileAttachmentSection(
            attachments: config.attachments,
            onAttach: (attachment) =>
                cubit.attachNodeFile(nodeId: node.id, attachment: attachment),
            onDetach: (id) =>
                cubit.detachNodeFile(nodeId: node.id, attachmentId: id),
          ),
          gap,
          NodeKnowledgeAttachmentSection(
            attachments: config.knowledgeAttachments,
            onAttach: (attachment) => cubit.attachNodeKnowledge(
              nodeId: node.id,
              attachment: attachment,
            ),
            onDetach: (id) =>
                cubit.detachNodeKnowledge(nodeId: node.id, attachmentId: id),
          ),
        ],
      ),
    );
  }
}

class _Orchestrator extends StatelessWidget {
  const _Orchestrator({required this.node, required this.config});

  final WorkflowNode node;
  final TeamworkNodeConfig config;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.ui_teamwork_instruction.tr(),
          style: SyscatTheme.taskBody,
        ),
        const SizedBox(height: AppSpacing.xs),
        TemplateExpressionTextField(
          value: config.instruction,
          cursorTarget: TaskBuilderCursorTargets.field(
            node.id,
            NodeFieldKey.instruction,
          ),
          suggestions: TemplateExpressionScope.suggestionsOf(context),
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: LocaleKeys.ui_teamwork_instruction_hint.tr(),
          ),
          onChanged: (text) => cubit.updateTeamworkInstruction(node.id, text),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          LocaleKeys.ui_teamwork_orchestrator_model.tr(),
          style: SyscatTheme.taskBodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        NodeLanguageModelField(
          selectedModelId: config.languageModelId,
          onChanged: (id) => cubit.updateTeamworkLanguageModel(node.id, id),
        ),
        FieldHelperText(LocaleKeys.ui_teamwork_tool_calls_hint.tr()),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.node, required this.config});

  final WorkflowNode node;
  final TeamworkNodeConfig config;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.ui_teamwork_result.tr(), style: SyscatTheme.taskBody),
        FieldHelperText(LocaleKeys.ui_teamwork_result_hint.tr()),
        StructuredOutputFieldsEditor(
          fields: config.outputFields,
          allowedTypes: StructuredFieldType.values,
          onChanged: (index, field) => cubit.updateTeamworkOutputField(
            nodeId: node.id,
            fieldIndex: index,
            field: field,
          ),
          onAdd: () => cubit.addTeamworkOutputField(node.id),
          onRemove: (index) => cubit.removeTeamworkOutputField(
            nodeId: node.id,
            fieldIndex: index,
          ),
        ),
      ],
    );
  }
}
