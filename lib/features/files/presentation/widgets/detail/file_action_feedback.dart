import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../domain/entities/file_failure.dart';
import '../../../domain/entities/team_file.dart';
import '../../cubits/file_actions_state.dart';
import '../../localization/file_failure_message.dart';

/// Rückmeldung zu einer abgeschlossenen Aktion als Snackbar. Abbrüche und
/// Fehler, die ein Dialog schon am Feld zeigt, bleiben still.
void showFileActionFeedback(
  BuildContext context,
  FileActionsState state, {
  required void Function(TeamFile file) onOpenCopy,
}) {
  final messenger = ScaffoldMessenger.of(context);
  switch (state) {
    case FileActionSucceeded(:final action, :final createdFile):
      messenger.showSnackBar(
        SnackBar(
          content: Text(_successText(action, createdFile)),
          action: createdFile == null
              ? null
              : SnackBarAction(
                  label: LocaleKeys.files_open.tr(),
                  onPressed: () => onOpenCopy(createdFile),
                ),
        ),
      );
    case FileActionFailed(:final action, :final kind)
        when !_isSilent(action, kind):
      messenger.showSnackBar(SnackBar(content: Text(fileFailureMessage(kind))));
    default:
      break;
  }
}

bool _isSilent(FileAction action, FileFailureKind kind) {
  if (kind == FileFailureKind.cancelled) return true;
  return action == FileAction.rename &&
      (kind == FileFailureKind.nameTaken ||
          kind == FileFailureKind.invalidFileName);
}

String _successText(FileAction action, TeamFile? createdFile) {
  return switch (action) {
    FileAction.rename => LocaleKeys.files_done_rename.tr(),
    FileAction.move => LocaleKeys.files_done_move.tr(),
    FileAction.copy => LocaleKeys.files_done_copy.tr(
      namedArgs: {'name': createdFile?.displayName ?? ''},
    ),
    FileAction.delete => LocaleKeys.files_file_deleted.tr(),
    FileAction.download => LocaleKeys.files_done_download.tr(),
    FileAction.restore => LocaleKeys.files_done_restore.tr(),
    FileAction.uploadVersion => LocaleKeys.files_done_upload_version.tr(),
    FileAction.saveText ||
    FileAction.saveImage => LocaleKeys.files_done_save.tr(),
  };
}
