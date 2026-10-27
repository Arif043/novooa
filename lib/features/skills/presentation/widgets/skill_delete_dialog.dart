import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

/// Fragt nach, bevor der Ordner einer Fähigkeit endgültig gelöscht wird.
Future<bool> confirmSkillDeletion(BuildContext context, String name) async {
  final confirmed = await showIosDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(LocaleKeys.ui_skill_delete_title.tr()),
      content: Text(
        LocaleKeys.ui_skill_delete_body.tr(namedArgs: {'name': name}),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.ui_loeschen.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
