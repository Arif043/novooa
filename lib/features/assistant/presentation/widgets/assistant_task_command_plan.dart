import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_task_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_executor.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_history.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class AssistantTaskCommandPlan extends StatefulWidget {
  const AssistantTaskCommandPlan({
    super.key,
    required this.commands,
    required this.taskBuilderCubit,
  });

  final List<AssistantTaskCommand> commands;
  final TaskBuilderCubit taskBuilderCubit;

  @override
  State<AssistantTaskCommandPlan> createState() =>
      _AssistantTaskCommandPlanState();
}

class _AssistantTaskCommandPlanState extends State<AssistantTaskCommandPlan> {
  int? _activeIndex;
  bool _isRunning = false;
  bool _isDone = false;
  TaskBuilderAgentCommandHistory? _history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlanHeader(
              isRunning: _isRunning,
              isDone: _isDone,
              onRun: _onRun,
              onUndo: _canUndo ? _undo : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...List.generate(widget.commands.length, _stepFor),
          ],
        ),
      ),
    );
  }

  Widget _stepFor(int index) {
    return _PlanStep(
      label: widget.commands[index].label,
      isActive: _activeIndex == index,
      isDone: _isDone || (_activeIndex != null && index < _activeIndex!),
    );
  }

  VoidCallback? get _onRun {
    return _isRunning || _isDone ? null : () => _runCommands();
  }

  Future<void> _runCommands() async {
    setState(() {
      _isRunning = true;
      _activeIndex = 0;
    });
    final history = await TaskBuilderAgentCommandExecutor(
      widget.taskBuilderCubit,
    ).execute(widget.commands, onStepChanged: _setActiveIndex);
    if (!mounted) return;
    setState(() {
      _history = history;
      _isRunning = false;
      _isDone = true;
      _activeIndex = null;
    });
  }

  void _setActiveIndex(int index) {
    if (!mounted) return;
    setState(() => _activeIndex = index);
  }

  bool get _canUndo => !_isRunning && _isDone && (_history?.canUndo ?? false);

  Future<void> _undo() async {
    final history = _history;
    if (history == null) return;
    await history.undo(widget.taskBuilderCubit);
    if (!mounted) return;
    setState(() {
      _isDone = false;
      _history = null;
      _activeIndex = null;
    });
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.isRunning,
    required this.isDone,
    required this.onRun,
    required this.onUndo,
  });

  final bool isRunning;
  final bool isDone;
  final VoidCallback? onRun;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.ads_click, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text('Aufgabe entwerfen', style: theme.textTheme.labelLarge),
        ),
        if (onUndo != null)
          IconButton(
            tooltip: 'Rückgängig',
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded),
          ),
        TextButton.icon(
          onPressed: onRun,
          icon: Icon(isDone ? Icons.check : Icons.play_arrow_rounded),
          label: Text(
            isDone
                ? 'Erledigt'
                : isRunning
                ? 'Läuft'
                : 'Ausführen',
          ),
        ),
      ],
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.mouse,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
