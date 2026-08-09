import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showIosDialog<String>(
      context: context,
      builder: (_) => const CreateFolderDialog(),
    );
  }

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Verzeichnis erstellen'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _submit(context),
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}
