import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';

class ApprovalReviewDialog extends StatefulWidget {
  const ApprovalReviewDialog({super.key, required this.run});

  final TaskRun run;

  static Future<void> show(BuildContext context, TaskRun run) {
    return showIosDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ActivityCubit>(),
        child: ApprovalReviewDialog(run: run),
      ),
    );
  }

  @override
  State<ApprovalReviewDialog> createState() => _ApprovalReviewDialogState();
}

class _ApprovalReviewDialogState extends State<ApprovalReviewDialog> {
  late final TextEditingController _outputController;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _outputController = TextEditingController(text: _reviewOutput);
  }

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.run.taskTitle),
      content: SizedBox(
        width: _dialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InstructionText(text: _instruction),
              const SizedBox(height: AppSpacing.lg),
              _ReviewOutputField(controller: _outputController),
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
          onPressed: _isSubmitting ? null : () => _approve(context),
          child: _isSubmitting
              ? const _SubmittingIndicator()
              : const Text('Bestätigen'),
        ),
      ],
    );
  }

  String get _instruction {
    final instruction = widget.run.reviewInstruction;
    if (instruction == null || instruction.trim().isEmpty) {
      return 'Prüfe das Ergebnis und gib es frei.';
    }
    return instruction;
  }

  String get _reviewOutput {
    return widget.run.reviewOutput ?? widget.run.finalOutput ?? '';
  }

  double _dialogWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width * 0.72;
  }

  Future<void> _approve(BuildContext context) async {
    await _submit(
      context,
      () => context.read<ActivityCubit>().approveRun(
        widget.run,
        _outputController.text,
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    await _submit(
      context,
      () => context.read<ActivityCubit>().rejectRun(widget.run),
    );
  }

  Future<void> _submit(
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
      const SnackBar(
        content: Text('Freigabe konnte nicht verarbeitet werden.'),
      ),
    );
  }
}

class _InstructionText extends StatelessWidget {
  const _InstructionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _ReviewOutputField extends StatelessWidget {
  const _ReviewOutputField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 8,
      maxLines: 14,
      decoration: const InputDecoration(
        labelText: 'Output',
        border: OutlineInputBorder(),
      ),
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
