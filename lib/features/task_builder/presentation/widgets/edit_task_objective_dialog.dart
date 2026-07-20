import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class EditTaskObjectiveDialog extends StatefulWidget {
  const EditTaskObjectiveDialog({super.key, required this.initialObjective});

  final String initialObjective;

  @override
  State<EditTaskObjectiveDialog> createState() =>
      _EditTaskObjectiveDialogState();
}

class _EditTaskObjectiveDialogState extends State<EditTaskObjectiveDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialObjective);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Notiz bearbeiten'),
      content: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: CupertinoTextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          placeholder: 'Ziel oder Notiz zur Aufgabe',
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
