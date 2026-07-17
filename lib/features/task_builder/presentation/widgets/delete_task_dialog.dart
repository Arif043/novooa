import 'package:flutter/material.dart';

class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({super.key, required this.taskTitle});

  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aufgabe löschen?'),
      content: Text(
        '„$taskTitle“ wird dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Löschen'),
        ),
      ],
    );
  }
}
