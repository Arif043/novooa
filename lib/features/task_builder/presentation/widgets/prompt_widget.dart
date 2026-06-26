import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/prompt_node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class PromptWidget extends StatefulWidget {
  const PromptWidget({super.key, required this.node, required this.cubit});

  final WorkflowNode node;
  final TaskBuilderCubit cubit;

  @override
  State<PromptWidget> createState() => _PromptWidgetState();
}

class _PromptWidgetState extends State<PromptWidget> {
  late PromptOutputType selectedOutput;
  late final TextEditingController _instructionController;
  late final TextEditingController _firstChoiceController;
  late final TextEditingController _secondChoiceController;

  @override
  void initState() {
    super.initState();
    selectedOutput = widget.node.promptConfig.outputType;
    _instructionController = _controller(widget.node.promptConfig.instruction);
    _firstChoiceController = _controller(widget.node.promptConfig.firstChoice);
    _secondChoiceController = _controller(
      widget.node.promptConfig.secondChoice,
    );
  }

  @override
  void didUpdateWidget(PromptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    selectedOutput = widget.node.promptConfig.outputType;
    if (oldWidget.node.id != widget.node.id) {
      _syncController(
        _instructionController,
        widget.node.promptConfig.instruction,
      );
      _syncController(
        _firstChoiceController,
        widget.node.promptConfig.firstChoice,
      );
      _syncController(
        _secondChoiceController,
        widget.node.promptConfig.secondChoice,
      );
    }
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _firstChoiceController.dispose();
    _secondChoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          SegmentedButton<PromptOutputType>(
            segments: const [
              ButtonSegment(
                value: PromptOutputType.text,
                label: Text('Freitext'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment(
                value: PromptOutputType.decision,
                label: Text('Entscheidung'),
                icon: Icon(Icons.list),
              ),
            ],
            selected: {selectedOutput},
            onSelectionChanged: _updateOutputType,
          ),
          if (selectedOutput == PromptOutputType.decision) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Mögliche Antworten', style: SyscatTheme.taskBodySmall),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _firstChoiceController,
              decoration: const InputDecoration(
                hintText: 'Hier kommt die erste Antwort',
              ),
              onChanged: (value) => _updateChoice(0, value),
            ),
            TextField(
              controller: _secondChoiceController,
              decoration: const InputDecoration(
                hintText: 'Hier kommt die zweite Antwort',
              ),
              onChanged: (value) => _updateChoice(1, value),
            ),
          ],
        ],
      ),
    );
  }

  TextEditingController _controller(String text) {
    return TextEditingController(text: text);
  }

  void _syncController(TextEditingController controller, String text) {
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateInstruction(String value) {
    widget.cubit.updatePromptInstruction(widget.node.id, value);
  }

  void _updateOutputType(Set<PromptOutputType> value) {
    final outputType = value.first;
    setState(() => selectedOutput = outputType);
    widget.cubit.updatePromptOutputType(widget.node.id, outputType);
  }

  void _updateChoice(int index, String value) {
    widget.cubit.updatePromptChoice(
      nodeId: widget.node.id,
      index: index,
      value: value,
    );
  }
}
