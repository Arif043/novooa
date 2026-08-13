import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_execution.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_executor.dart';

import 'assistant_action_plan_parts.dart';

class AssistantActionPlan extends StatefulWidget {
  const AssistantActionPlan({super.key, required this.actions});

  final List<AssistantPlanAction> actions;

  @override
  State<AssistantActionPlan> createState() => _AssistantActionPlanState();
}

class _AssistantActionPlanState extends State<AssistantActionPlan> {
  int? _activeIndex;
  bool _isRunning = false;
  bool _isDone = false;
  String? _errorMessage;
  AssistantPlanExecution? _execution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: _decoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: _content(theme),
      ),
    );
  }

  BoxDecoration _decoration(ThemeData theme) {
    return BoxDecoration(
      border: Border.all(color: theme.colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    );
  }

  Widget _content(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children(theme),
    );
  }

  List<Widget> _children(ThemeData theme) {
    return [
      AssistantActionPlanHeader(
        isRunning: _isRunning,
        isDone: _isDone,
        onRun: _onRun,
        onUndo: _canUndo ? _undo : null,
      ),
      const SizedBox(height: AppSpacing.xs),
      ...List.generate(widget.actions.length, _stepFor),
      if (_errorMessage case final errorMessage?)
        _errorText(theme, errorMessage),
    ];
  }

  Widget _errorText(ThemeData theme, String errorMessage) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        errorMessage,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _stepFor(int index) {
    return AssistantActionPlanStep(
      label: widget.actions[index].label,
      isActive: _activeIndex == index,
      isDone: _isDone || (_activeIndex != null && index < _activeIndex!),
    );
  }

  VoidCallback? get _onRun {
    return _isRunning || _isDone ? null : _runActions;
  }

  Future<void> _runActions() async {
    setState(() {
      _isRunning = true;
      _activeIndex = 0;
      _errorMessage = null;
    });
    await _completeActionRun();
  }

  Future<void> _completeActionRun() async {
    try {
      final execution = await const AssistantPlanExecutor().execute(
        widget.actions,
        onStepChanged: _setActiveIndex,
      );
      _showSuccessfulRun(execution);
    } catch (_) {
      _showFailedRun();
    }
  }

  void _showSuccessfulRun(AssistantPlanExecution execution) {
    if (!mounted) return;
    setState(() {
      _execution = execution;
      _isRunning = false;
      _isDone = true;
      _activeIndex = null;
    });
  }

  void _showFailedRun() {
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _activeIndex = null;
      _errorMessage = 'Der Vorschlag konnte nicht angewendet werden.';
    });
  }

  void _setActiveIndex(int index) {
    if (!mounted) return;
    setState(() => _activeIndex = index);
  }

  bool get _canUndo => !_isRunning && _isDone && (_execution?.canUndo ?? false);

  Future<void> _undo() async {
    final execution = _execution;
    if (execution == null) return;
    await execution.undo();
    if (!mounted) return;
    setState(() {
      _isDone = false;
      _execution = null;
      _activeIndex = null;
    });
  }
}
