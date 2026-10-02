import 'package:syscat2/features/task_builder/presentation/widgets/language_model_picker_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/config/mvp_feature_flags.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import '../../domain/entities/employee_attachment.dart';
import '../../domain/entities/node_attachment.dart';
import '../../domain/entities/knowledge_attachment.dart';
import '../../domain/entities/skill_attachment.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/node_language_models_cubit.dart';
import '../cubits/node_language_models_state.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_file_attachment_section.dart';
import 'node_knowledge_attachment_section.dart';
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
          Text('Prompt', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TemplateExpressionTextField(
            value: config.instruction,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Hier kommt die Anweisung',
            ),
            onChanged: _updateInstruction,
          ),
          const SizedBox(height: AppSpacing.md),
          _languageModelField(context, config),
          const SizedBox(height: AppSpacing.md),
          Text('Ausgabe', style: SyscatTheme.taskBody),
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
                  label: 'Freitext',
                ),
                PromptOutputType.decision: _outputTypeIcon(
                  icon: Icons.call_split_outlined,
                  label: 'Entscheidung',
                ),
                PromptOutputType.structured: _outputTypeIcon(
                  icon: Icons.data_object_outlined,
                  label: 'Strukturierte Ausgabe',
                ),
                PromptOutputType.image: _outputTypeIcon(
                  icon: Icons.image_outlined,
                  label: 'Bild',
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
          const SizedBox(height: AppSpacing.md),
          NodeFileAttachmentSection(
            attachments: config.attachments,
            onAttach: _attachFile,
            onDetach: _detachFile,
          ),
          const SizedBox(height: AppSpacing.md),
          NodeKnowledgeAttachmentSection(
            attachments: config.knowledgeAttachments,
            onAttach: _attachKnowledge,
            onDetach: _detachKnowledge,
          ),
          if (MvpFeatureFlags.promptDelegationEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            PromptResourceSelection(
              config: config,
              onAttachSkill: _attachSkill,
              onDetachSkill: _detachSkill,
              onAssignEmployee: _assignEmployee,
              onUnassignEmployee: _unassignEmployee,
            ),
          ],
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

  Widget _languageModelField(BuildContext context, PromptNodeConfig config) {
    if (!_hasLanguageModelsProvider(context)) {
      return LanguageModelPickerField(
        models: const [],
        selectedModelId: '',
        enabled: false,
        onChanged: (_) {},
      );
    }
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) => LanguageModelPickerField(
        models: state.models,
        selectedModelId: config.languageModelId,
        enabled: state.status == NodeLanguageModelsStatus.ready,
        onChanged: (modelId) => context
            .read<TaskBuilderCubit>()
            .updatePromptLanguageModel(widget.node.id, modelId),
      ),
    );
  }

  bool _hasLanguageModelsProvider(BuildContext context) {
    try {
      BlocProvider.of<NodeLanguageModelsCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
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

  void _assignEmployee(EmployeeAttachment attachment) {
    context.read<TaskBuilderCubit>().assignNodeEmployee(
      nodeId: widget.node.id,
      attachment: attachment,
    );
  }

  void _unassignEmployee() {
    context.read<TaskBuilderCubit>().unassignNodeEmployee(
      nodeId: widget.node.id,
    );
  }
}
