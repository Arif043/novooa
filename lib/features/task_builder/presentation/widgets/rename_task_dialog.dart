import 'package:flutter/cupertino.dart';

class RenameTaskDialog extends StatefulWidget {
  const RenameTaskDialog({super.key, required this.initialTitle});

  final String initialTitle;

  @override
  State<RenameTaskDialog> createState() => _RenameTaskDialogState();
}

class _RenameTaskDialogState extends State<RenameTaskDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Aufgabe umbenennen'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: _controller,
          autofocus: true,
          placeholder: 'Name der Aufgabe',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(context),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _submit(context),
          child: const Text('Umbenennen'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }
}
