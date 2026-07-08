import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import '../../domain/entities/node_attachment.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_file_attachment_section.dart';
import 'prompt_choice_field.dart';

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
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
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
          Text('Ausgabe', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          CupertinoSlidingSegmentedControl<PromptOutputType>(
            groupValue: selectedOutput,
            backgroundColor: SyscatTheme.primaryOrangeLighter,
            children: const {
              PromptOutputType.text: Text('Freitext'),
              PromptOutputType.decision: Text('Entscheidung'),
            },
            onValueChanged: (value) {
              _updateOutputType({value!});
            },
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
          const SizedBox(height: AppSpacing.md),
          NodeFileAttachmentSection(
            attachments: config.attachments,
            onAttach: _attachFile,
            onDetach: _detachFile,
          ),
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
}
