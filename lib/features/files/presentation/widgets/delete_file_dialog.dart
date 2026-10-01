import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

class DeleteFileDialog extends StatelessWidget {
  const DeleteFileDialog({super.key, required this.fileName});

  final String fileName;

  static Future<bool?> show(BuildContext context, String fileName) {
    return showIosDialog<bool>(
      context: context,
      builder: (_) => DeleteFileDialog(fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Datei löschen?'),
      content: Text(
        '„$fileName“ wird mit allen Versionen endgültig gelöscht. '
        'Aufgaben, die darauf reagieren, werden dadurch gestartet.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Löschen'),
        ),
      ],
    );
  }
}
