import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/config/mvp_feature_flags.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/employee_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'node_employee_section.dart';
import 'node_skill_attachment_section.dart';

class IterativeRefinementWidget extends StatefulWidget {
  const IterativeRefinementWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<IterativeRefinementWidget> createState() =>
      _IterativeRefinementWidgetState();
}

class _IterativeRefinementWidgetState extends State<IterativeRefinementWidget> {
  late final TextEditingController _optimizerController;
  late final TextEditingController _critiqueController;

  IterativeRefinementNodeConfig get _config {
    return widget.node.config as IterativeRefinementNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _optimizerController = TextEditingController(text: _config.optimizerPrompt);
    _critiqueController = TextEditingController(text: _config.critiquePrompt);
  }

  @override
  void didUpdateWidget(IterativeRefinementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_optimizerController, _config.optimizerPrompt);
    _syncController(_critiqueController, _config.critiquePrompt);
  }

  @override
  void dispose() {
    _optimizerController.dispose();
    _critiqueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Iterative Verfeinerung', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _optimizerController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Optimierer-Prompt'),
            onChanged: _updateOptimizer,
          ),
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
            backgroundColor: SyscatTheme.surfaceContainer,
            thumbColor: SyscatTheme.glassSurface,
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
          if (MvpFeatureFlags.skillsEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            NodeSkillAttachmentSection(
              attachments: _config.skillAttachments,
              onAttach: _attachSkill,
              onDetach: _detachSkill,
            ),
          ],
          if (MvpFeatureFlags.employeesEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            NodeEmployeeSection(
              assigned: _config.employee,
              onAssign: _assignEmployee,
              onUnassign: _unassignEmployee,
            ),
          ],
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
