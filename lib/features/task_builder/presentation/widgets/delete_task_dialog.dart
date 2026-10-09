import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';

class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({super.key, required this.taskTitle});

  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(LocaleKeys.ui_aufgabe_loeschen.tr()),
      content: Text(
        LocaleKeys.ui_delete_task_body.tr(namedArgs: {'title': taskTitle}),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(LocaleKeys.ui_loeschen.tr()),
        ),
      ],
    );
  }
}
