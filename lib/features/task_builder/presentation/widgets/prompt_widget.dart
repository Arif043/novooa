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
import 'prompt_choice_field.dart';
import 'prompt_resource_selection.dart';
import 'prompt_structured_output_section.dart';

class PromptWidget extends StatefulWidget {
  const PromptWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<PromptWidget> createState() => _PromptWidgetState();
}

class _PromptWidgetState extends State<PromptWidget> {
  late PromptOutputType selectedOutput;
  late final TextEditingController _instructionController;
  final List<TextEditingController> _choiceControllers = [];

  @override
  void initState() {
    super.initState();
    final config = widget.node.config as PromptNodeConfig;
    selectedOutput = config.outputType;
    _instructionController = TextEditingController(text: config.instruction);
    _syncChoiceControllers(config.choices);
  }

  @override
  void didUpdateWidget(PromptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final config = widget.node.config as PromptNodeConfig;
    selectedOutput = config.outputType;
    _syncChoiceControllers(config.choices);
  }

  @override
  void dispose() {
    _instructionController.dispose();
    for (final controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
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
          TextField(
            controller: _instructionController,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CupertinoSlidingSegmentedControl<PromptOutputType>(
              groupValue: selectedOutput,
              backgroundColor: SyscatTheme.surfaceContainer,
              thumbColor: SyscatTheme.glassSurface,
              children: const {
                PromptOutputType.text: Text('Freitext'),
                PromptOutputType.decision: Text('Entscheidung'),
                PromptOutputType.structured: Text('Strukturierte Ausgabe'),
                PromptOutputType.image: Text('Bild'),
              },
              onValueChanged: (value) {
                _updateOutputType({value!});
              },
            ),
          ),
          Visibility(
            visible: selectedOutput == .decision,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text('Mögliche Antworten', style: SyscatTheme.taskBodySmall),
                const SizedBox(height: AppSpacing.xs),
                ListView.builder(
                  itemCount: _choiceControllers.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return PromptChoiceField(
                      controller: _choiceControllers[index],
                      index: index,
                      canRemove: _choiceControllers.length > 1,
                      onChanged: _updateChoice,
                      onRemove: _removeChoice,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _addChoice,
                  child: const Text('Antwort hinzufügen'),
                ),
              ],
            ),
          ),
          Visibility(
            visible: selectedOutput == .structured,
            child: PromptStructuredOutputSection(
              fields: config.structuredFields,
              onChanged: _updateStructuredField,
              onAdd: _addStructuredField,
              onRemove: _removeStructuredField,
            ),
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

  void _syncChoiceControllers(List<String> choices) {
    while (_choiceControllers.length < choices.length) {
      _choiceControllers.add(TextEditingController());
    }
    while (_choiceControllers.length > choices.length) {
      _choiceControllers.removeLast().dispose();
    }
    for (var index = 0; index < choices.length; index++) {
      _syncController(_choiceControllers[index], choices[index]);
    }
  }

  Widget _languageModelField(BuildContext context, PromptNodeConfig config) {
    final available = _hasLanguageModelsProvider(context);
    if (!available) {
      return DropdownButtonFormField<String>(
        initialValue: '',
        decoration: InputDecoration(labelText: 'Sprachmodell'),
        items: [
          DropdownMenuItem(value: '', child: Text('Standardmodell verwenden')),
        ],
        onChanged: null,
      );
    }
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) => DropdownButtonFormField<String>(
        initialValue:
            state.models.any((model) => model.id == config.languageModelId)
            ? config.languageModelId
            : '',
        decoration: const InputDecoration(labelText: 'Sprachmodell'),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('Standardmodell verwenden'),
          ),
          ...state.models.map(
            (model) => DropdownMenuItem(
              value: model.id,
              child: Text('${model.name} (${model.modelId})'),
            ),
          ),
        ],
        onChanged: state.status == NodeLanguageModelsStatus.ready
            ? (modelId) => context
                  .read<TaskBuilderCubit>()
                  .updatePromptLanguageModel(widget.node.id, modelId ?? '')
            : null,
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

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
