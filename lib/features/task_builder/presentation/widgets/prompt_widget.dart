import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import '../../domain/entities/node_attachment.dart';
import '../../domain/entities/knowledge_attachment.dart';
import '../../domain/entities/skill_attachment.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_file_attachment_section.dart';
import 'node_language_model_field.dart';
import 'node_knowledge_attachment_section.dart';
import 'prompt_generation_options_for_model.dart';
import 'prompt_resource_selection.dart';
import 'prompt_output_configuration.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class PromptWidget extends StatefulWidget {
  const PromptWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<PromptWidget> createState() => _PromptWidgetState();
}

class _PromptWidgetState extends State<PromptWidget> {
  late PromptOutputType selectedOutput;

  @override
  void initState() {
    super.initState();
    final config = widget.node.config as PromptNodeConfig;
    selectedOutput = config.outputType;
  }

  @override
  void didUpdateWidget(PromptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final config = widget.node.config as PromptNodeConfig;
    selectedOutput = config.outputType;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.node.config as PromptNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_prompt.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TemplateExpressionTextField(
            value: config.instruction,
            cursorTarget: TaskBuilderCursorTargets.field(
              widget.node.id,
              NodeFieldKey.instruction,
            ),
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_hier_kommt_die_anweisung.tr(),
            ),
            onChanged: _updateInstruction,
          ),
          const SizedBox(height: AppSpacing.md),
          NodeLanguageModelField(
            selectedModelId: config.languageModelId,
            onChanged: (modelId) => context
                .read<TaskBuilderCubit>()
                .updatePromptLanguageModel(widget.node.id, modelId),
          ),
          PromptGenerationOptionsForModel(
            options: config.generationOptions,
            languageModelId: config.languageModelId,
            onChanged: (options) => context
                .read<TaskBuilderCubit>()
                .updatePromptGenerationOptions(widget.node.id, options),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(LocaleKeys.ui_ausgabe.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<PromptOutputType>(
              groupValue: selectedOutput,
              backgroundColor: SyscatTheme.surfaceContainer,
              thumbColor: SyscatTheme.glassSurface,
              children: {
                PromptOutputType.text: _outputTypeIcon(
                  icon: Icons.notes_outlined,
                  label: LocaleKeys.ui_freitext.tr(),
                ),
                PromptOutputType.decision: _outputTypeIcon(
                  icon: Icons.call_split_outlined,
                  label: LocaleKeys.ui_entscheidung.tr(),
                ),
                PromptOutputType.structured: _outputTypeIcon(
                  icon: Icons.data_object_outlined,
                  label: LocaleKeys.ui_strukturierte_ausgabe.tr(),
                ),
                PromptOutputType.image: _outputTypeIcon(
                  icon: Icons.image_outlined,
                  label: LocaleKeys.ui_bild.tr(),
                ),
              },
              onValueChanged: (value) {
                _updateOutputType({value!});
              },
            ),
          ),
          PromptOutputConfiguration(
            outputType: selectedOutput,
            choices: config.choices,
            structuredFields: config.structuredFields,
            onChoiceChanged: _updateChoice,
            onChoiceAdded: _addChoice,
            onChoiceRemoved: _removeChoice,
            onStructuredFieldChanged: _updateStructuredField,
            onStructuredFieldAdded: _addStructuredField,
            onStructuredFieldRemoved: _removeStructuredField,
          ),
          const Divider(height: AppSpacing.lg * 2),
          NodeFileAttachmentSection(
            attachments: config.attachments,
            onAttach: _attachFile,
            onDetach: _detachFile,
          ),
          const Divider(height: AppSpacing.lg * 2),
          NodeKnowledgeAttachmentSection(
            attachments: config.knowledgeAttachments,
            onAttach: _attachKnowledge,
            onDetach: _detachKnowledge,
          ),
          const Divider(height: AppSpacing.lg * 2),
          PromptResourceSelection(
            employeeId: config.employeeId,
            skillAttachments: config.skillAttachments,
            onAttachSkill: _attachSkill,
            onDetachSkill: _detachSkill,
            onAssignEmployee: _assignEmployee,
            onUnassignEmployee: _unassignEmployee,
          ),
        ],
      ),
    );
  }

  Widget _outputTypeIcon({required IconData icon, required String label}) {
    return Tooltip(
      message: label,
      child: Semantics(label: label, child: Icon(icon)),
    );
  }

  void _updateInstruction(String value) {
    context.read<TaskBuilderCubit>().updatePromptInstruction(
      widget.node.id,
      value,
    );
  }

  void _updateOutputType(Set<PromptOutputType> value) {
    final outputType = value.first;
    context.read<TaskBuilderCubit>().updatePromptOutputType(
      widget.node.id,
      outputType,
    );
  }

  void _updateChoice(int index, String value) {
    context.read<TaskBuilderCubit>().updatePromptChoice(
      nodeId: widget.node.id,
      choiceIndex: index,
      value: value,
    );
  }

  void _addChoice() {
    context.read<TaskBuilderCubit>().addPromptChoice(widget.node.id);
  }

  void _removeChoice(int index) {
    context.read<TaskBuilderCubit>().removePromptChoice(
      nodeId: widget.node.id,
      choiceIndex: index,
    );
  }

  void _updateStructuredField(int index, StructuredOutputField field) {
    context.read<TaskBuilderCubit>().updatePromptStructuredField(
      nodeId: widget.node.id,
      fieldIndex: index,
      field: field,
    );
  }

  void _addStructuredField() {
    context.read<TaskBuilderCubit>().addPromptStructuredField(widget.node.id);
  }

  void _removeStructuredField(int index) {
    context.read<TaskBuilderCubit>().removePromptStructuredField(
      nodeId: widget.node.id,
      fieldIndex: index,
    );
  }

  void _attachFile(NodeAttachment attachment) {
    context.read<TaskBuilderCubit>().attachNodeFile(
      nodeId: widget.node.id,
      attachment: attachment,
    );
  }

  void _detachFile(String attachmentId) {
    context.read<TaskBuilderCubit>().detachNodeFile(
      nodeId: widget.node.id,
      attachmentId: attachmentId,
    );
  }

  void _attachKnowledge(KnowledgeAttachment attachment) {
    context.read<TaskBuilderCubit>().attachNodeKnowledge(
      nodeId: widget.node.id,
      attachment: attachment,
    );
  }

  void _detachKnowledge(String attachmentId) {
    context.read<TaskBuilderCubit>().detachNodeKnowledge(
      nodeId: widget.node.id,
      attachmentId: attachmentId,
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
}
