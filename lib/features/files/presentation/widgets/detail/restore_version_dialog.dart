import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

/// Rückfrage vor dem Wiederherstellen; [versionDate] ist bereits formatiert.
Future<bool> confirmRestoreVersion(
  BuildContext context, {
  required String versionDate,
}) async {
  final confirmed = await showIosDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(LocaleKeys.files_restore_title.tr()),
      content: Text(
        LocaleKeys.files_restore_body.tr(namedArgs: {'date': versionDate}),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.files_version_restore.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
