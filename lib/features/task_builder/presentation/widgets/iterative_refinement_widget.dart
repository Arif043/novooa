import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class IterativeRefinementWidget extends StatefulWidget {
  const IterativeRefinementWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<IterativeRefinementWidget> createState() =>
      _IterativeRefinementWidgetState();
}

class _IterativeRefinementWidgetState extends State<IterativeRefinementWidget> {
  late final TextEditingController _critiqueController;

  IterativeRefinementNodeConfig get _config {
    return widget.node.config as IterativeRefinementNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _critiqueController = TextEditingController(text: _config.critiquePrompt);
  }

  @override
  void didUpdateWidget(IterativeRefinementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_critiqueController, _config.critiquePrompt);
  }

  @override
  void dispose() {
    _critiqueController.dispose();
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
          Text('Iterative Verfeinerung', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _critiqueController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Kritik'),
            onChanged: _updateCritique,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Maximale Iterationen', style: SyscatTheme.taskBodySmall),
          const SizedBox(height: AppSpacing.xs),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _config.maxIterations,
            backgroundColor: SyscatTheme.primaryOrangeLighter,
            children: {
              for (var value = 1; value <= 5; value++) value: Text('$value'),
            },
            onValueChanged: _updateMaxIterations,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Verfeinert die Ausgabe des vorherigen Bausteins.',
            style: SyscatTheme.taskBodySmall,
          ),
        ],
      ),
    );
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateCritique(String value) {
    context.read<TaskBuilderCubit>().updateIterativeCritique(
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
