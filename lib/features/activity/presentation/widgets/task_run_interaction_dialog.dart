import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_media_input.dart';
import '../cubits/activity_cubit.dart';
import 'task_run_dialog_input_submission.dart';
import 'task_run_interaction_content.dart';
import 'task_run_interaction_form_state.dart';
import 'task_run_submitting_indicator.dart';

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
  late final TaskRunInteractionFormState _form;
  MediaInputSubmission? _mediaSubmission;
  var _isSubmitting = false;
  var _isPicking = false;

  bool get _requiresDialogInput => widget.run.requiresDialogInput;
  bool get _requiresMediaInput => widget.run.requiresMediaInput;

  @override
  void initState() {
    super.initState();
    _form = TaskRunInteractionFormState(widget.run);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.run.taskTitle),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.72,
        child: SingleChildScrollView(
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodyMedium,
            child: TaskRunInteractionContent.withInstruction(
              run: widget.run,
              content: TaskRunInteractionContent(
                run: widget.run,
                formKey: _form.formKey,
                formValues: _form.values,
                controllers: _form.controllers,
                outputController: _form.outputController,
                mediaSubmission: _mediaSubmission,
                isPicking: _isPicking,
                onFormValueChanged: (name, value) => setState(() {
                  _form.values[name] = value;
                }),
                onPickMedia: _pickMedia,
                onClearMedia: () => setState(() => _mediaSubmission = null),
              ),
            ),
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
              ? const TaskRunSubmittingIndicator()
              : Text(
                  _requiresDialogInput || _requiresMediaInput
                      ? 'Absenden'
                      : 'Bestätigen',
                ),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_requiresDialogInput && !_form.formKey.currentState!.validate()) {
      return;
    }
    if (_requiresMediaInput && _mediaSubmission == null) {
      _showMessage(context, 'Bitte wähle ein Bild aus.');
      return;
    }
    final action = _requiresDialogInput
        ? _submitDialogInput
        : _requiresMediaInput
        ? _submitMediaInput
        : _approve;
    await _runAction(context, action);
  }

  Future<void> _approve() => context.read<ActivityCubit>().approveRun(
    widget.run,
    _form.outputController.text,
  );

  Future<void> _submitDialogInput() {
    return context.read<ActivityCubit>().submitDialogInput(
      widget.run,
      dialogInputSubmissionValues(
        widget.run.dialogInputFields,
        _form.controllers,
        _form.values,
      ),
    );
  }

  Future<void> _submitMediaInput() {
    return context.read<ActivityCubit>().submitMediaInput(
      widget.run,
      _mediaSubmission!,
    );
  }

  Future<void> _pickMedia(TaskRunMediaInputSource source) async {
    setState(() => _isPicking = true);
    try {
      final submission = await context.read<ActivityCubit>().pickMediaInput(
        widget.run,
        source,
      );
      if (mounted && submission != null) {
        setState(() => _mediaSubmission = submission);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(context, 'Bild konnte nicht ausgewählt werden.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
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
      if (context.mounted) {
        _showMessage(context, 'Eingabe konnte nicht verarbeitet werden.');
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
