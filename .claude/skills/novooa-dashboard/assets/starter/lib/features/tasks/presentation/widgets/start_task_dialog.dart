import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/dashboard_task.dart';

/// Fragt die optionale Eingabe ab; `null` heißt abgebrochen.
Future<String?> showStartTaskDialog(BuildContext context, DashboardTask task) {
  return showDialog<String>(
    context: context,
    builder: (_) => _StartTaskDialog(task: task),
  );
}

class _StartTaskDialog extends StatefulWidget {
  const _StartTaskDialog({required this.task});

  final DashboardTask task;

  @override
  State<_StartTaskDialog> createState() => _StartTaskDialogState();
}

class _StartTaskDialogState extends State<_StartTaskDialog> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task.title),
      content: TextField(
        controller: _input,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: DashboardKeys.tasksContext.tr(),
          hintText: DashboardKeys.tasksContextHint.tr(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(DashboardKeys.cancel.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_input.text),
          child: Text(DashboardKeys.tasksStart.tr()),
        ),
      ],
    );
  }
}
