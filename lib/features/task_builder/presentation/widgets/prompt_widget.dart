import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class PromptWidget extends StatefulWidget {
  const PromptWidget({super.key, required this.node});

  final WorkflowNode node;

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
    final config = widget.node.config as PromptNodeConfig;
    selectedOutput = config.outputType;
    _instructionController = _controller(config.instruction);
    _firstChoiceController = _controller(config.firstChoice);
    _secondChoiceController = _controller(config.secondChoice);
  }

  // @override
  // void didUpdateWidget(PromptWidget oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // selectedOutput = config.outputType;
  //   if (oldWidget.node.id != widget.node.id) {
  //     _syncController(_instructionController, config.instruction);
  //     _syncController(_firstChoiceController, config.firstChoice);
  //     _syncController(_secondChoiceController, config.secondChoice);
  //   }
  // }

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
          CupertinoSlidingSegmentedControl<PromptOutputType>(
            groupValue: selectedOutput,
            backgroundColor: SyscatTheme.primaryOrangeLighter,
            children: {
              PromptOutputType.text: Text('Freitext'),
              PromptOutputType.decision: Text('Entscheidung'),
            },
            onValueChanged: (value) {
              _updateOutputType({value!});
            },
          ),
          // SegmentedButton<PromptOutputType>(
          //   segments: const [
          //     ButtonSegment(
          //       value: .text,
          //       label: Text('Freitext'),
          //       icon: Icon(Icons.text_fields),
          //     ),
          //     ButtonSegment(
          //       value: .decision,
          //       label: Text('Entscheidung'),
          //       icon: Icon(Icons.list),
          //     ),
          //   ],
          //   selected: {selectedOutput},
          //   onSelectionChanged: _updateOutputType,
          // ),

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
    context.read<TaskBuilderCubit>().updatePromptInstruction(
      widget.node.id,
      value,
    );
  }

  void _updateOutputType(Set<PromptOutputType> value) {
    debugPrint('>>> ${value.toString()}');
    final outputType = value.first;
    setState(() => selectedOutput = outputType);
    debugPrint('>>> ${selectedOutput.toString()}');
    context.read<TaskBuilderCubit>().updatePromptOutputType(
      widget.node.id,
      outputType,
    );
  }

  void _updateChoice(int index, String value) {
    context.read<TaskBuilderCubit>().updatePromptChoice(
      nodeId: widget.node.id,
      index: index,
      value: value,
    );
  }
}
