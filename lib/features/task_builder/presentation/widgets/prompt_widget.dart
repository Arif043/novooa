import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/prompt_node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class PromptWidget extends StatelessWidget {
  const PromptWidget({super.key, required this.node, required this.cubit});

  final WorkflowNode node;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final config = node.promptConfig;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PromptHeader(node: node),
            const SizedBox(height: AppSpacing.lg),
            _InstructionField(node: node, cubit: cubit),
            const SizedBox(height: AppSpacing.md),
            _OutputTypeSelector(node: node, cubit: cubit),
            if (config.outputType == PromptOutputType.decision)
              _ChoiceFields(node: node, cubit: cubit),
          ],
        ),
      ),
    );
  }
}

class _PromptHeader extends StatelessWidget {
  const _PromptHeader({required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.text_fields, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(node.title, style: textTheme.titleLarge)),
      ],
    );
  }
}

class _InstructionField extends StatelessWidget {
  const _InstructionField({required this.node, required this.cubit});

  final WorkflowNode node;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('${node.id.value}.instruction'),
      initialValue: node.promptConfig.instruction,
      minLines: 4,
      maxLines: 8,
      decoration: const InputDecoration(
        labelText: 'Anweisung',
        hintText: 'Beschreibe, was das Sprachmodell tun soll.',
      ),
      onChanged: (value) => cubit.updatePromptInstruction(node.id, value),
    );
  }
}

class _OutputTypeSelector extends StatelessWidget {
  const _OutputTypeSelector({required this.node, required this.cubit});

  final WorkflowNode node;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PromptOutputType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: PromptOutputType.text,
          label: Text('Freitext'),
          icon: Icon(Icons.notes),
        ),
        ButtonSegment(
          value: PromptOutputType.decision,
          label: Text('Entscheidung'),
          icon: Icon(Icons.checklist),
        ),
      ],
      selected: {node.promptConfig.outputType},
      onSelectionChanged: (selection) {
        cubit.updatePromptOutputType(node.id, selection.first);
      },
    );
  }
}

class _ChoiceFields extends StatelessWidget {
  const _ChoiceFields({required this.node, required this.cubit});

  final WorkflowNode node;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _ChoiceField(node: node, cubit: cubit, index: 0),
          const SizedBox(height: AppSpacing.sm),
          _ChoiceField(node: node, cubit: cubit, index: 1),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.node,
    required this.cubit,
    required this.index,
  });

  final WorkflowNode node;
  final TaskBuilderCubit cubit;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('${node.id.value}.choice.$index'),
      initialValue: node.promptConfig.choices[index],
      decoration: InputDecoration(labelText: 'Antwort ${index + 1}'),
      onChanged: (value) {
        cubit.updatePromptChoice(nodeId: node.id, index: index, value: value);
      },
    );
  }
}
