import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';
import 'task_run_dialog_input_form.dart';
import 'task_run_dialog_input_submission.dart';

class TaskRunInteractionDialog extends StatefulWidget {
  const TaskRunInteractionDialog({super.key, required this.run});

  final TaskRun run;

  static Future<void> show(BuildContext context, TaskRun run) {
    return showIosDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ActivityCubit>(),
        child: TaskRunInteractionDialog(run: run),
      ),
    );
  }

  @override
  State<TaskRunInteractionDialog> createState() =>
      _TaskRunInteractionDialogState();
}

class _TaskRunInteractionDialogState extends State<TaskRunInteractionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _formValues = <String, Object?>{};
  final _controllers = <String, TextEditingController>{};
  late final TextEditingController _outputController;
  var _isSubmitting = false;

  bool get _requiresDialogInput => widget.run.requiresDialogInput;

  @override
  void initState() {
    super.initState();
    _outputController = TextEditingController(text: _reviewOutput);
    _initializeDialogInput();
  }

  @override
  void dispose() {
    _outputController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.run.taskTitle),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.72,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_instruction, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              if (_requiresDialogInput)
                _dialogInputForm()
              else
                _reviewOutputField(),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: _isSubmitting ? null : () => _reject(context),
          child: const Text('Ablehnen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _isSubmitting ? null : () => _submit(context),
          child: _isSubmitting
              ? const _SubmittingIndicator()
              : Text(_requiresDialogInput ? 'Absenden' : 'Bestätigen'),
        ),
      ],
    );
  }

  Widget _dialogInputForm() {
    return TaskRunDialogInputForm(
      formKey: _formKey,
      fields: widget.run.dialogInputFields,
      controllers: _controllers,
      values: _formValues,
      onValueChanged: (name, value) => setState(() {
        _formValues[name] = value;
      }),
    );
  }

  Widget _reviewOutputField() {
    return TextField(
      controller: _outputController,
      minLines: 8,
      maxLines: 14,
      decoration: const InputDecoration(labelText: 'Output'),
    );
  }

  String get _instruction {
    return widget.run.reviewInstruction?.trim().isNotEmpty == true
        ? widget.run.reviewInstruction!
        : 'Prüfe das Ergebnis und gib es frei.';
  }

  String get _reviewOutput =>
      widget.run.reviewOutput ?? widget.run.finalOutput ?? '';

  void _initializeDialogInput() {
    initializeDialogInput(
      widget.run.dialogInputFields,
      _controllers,
      _formValues,
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_requiresDialogInput && !_formKey.currentState!.validate()) {
      return;
    }
    final action = _requiresDialogInput ? _submitDialogInput : _approve;
    await _runAction(context, action);
  }

  Future<void> _approve() {
    return context.read<ActivityCubit>().approveRun(
      widget.run,
      _outputController.text,
    );
  }

  Future<void> _submitDialogInput() {
    return context.read<ActivityCubit>().submitDialogInput(
      widget.run,
      dialogInputSubmissionValues(
        widget.run.dialogInputFields,
        _controllers,
        _formValues,
      ),
    );
  }

  Future<void> _reject(BuildContext context) {
    return _runAction(
      context,
      () => context.read<ActivityCubit>().rejectRun(widget.run),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) _showFailure(context);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eingabe konnte nicht verarbeitet werden.')),
    );
  }
}

class _SubmittingIndicator extends StatelessWidget {
  const _SubmittingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: AppSpacing.md,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
