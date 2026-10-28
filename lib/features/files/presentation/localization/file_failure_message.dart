import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/file_failure.dart';

/// Sichtbarer Text zu einem Fehler der Dateiablage.
String fileFailureMessage(FileFailureKind kind) {
  return switch (kind) {
    FileFailureKind.unauthenticated => LocaleKeys.files_failure_unauthenticated,
    FileFailureKind.noFileSelected => LocaleKeys.files_failure_no_file_selected,
    FileFailureKind.loadFailed => LocaleKeys.files_failure_load,
    FileFailureKind.uploadFailed => LocaleKeys.files_failure_upload,
    FileFailureKind.downloadFailed => LocaleKeys.files_failure_download,
    FileFailureKind.createFolderFailed =>
      LocaleKeys.files_failure_create_folder,
    FileFailureKind.deleteFailed => LocaleKeys.files_failure_delete,
    FileFailureKind.invalidFolderName =>
      LocaleKeys.files_failure_invalid_folder_name,
    FileFailureKind.invalidFileName =>
      LocaleKeys.files_failure_invalid_file_name,
    FileFailureKind.nameTaken => LocaleKeys.files_failure_name_taken,
    FileFailureKind.renameFailed => LocaleKeys.files_failure_rename,
    FileFailureKind.moveFailed => LocaleKeys.files_failure_move,
    FileFailureKind.copyFailed => LocaleKeys.files_failure_copy,
    FileFailureKind.restoreFailed => LocaleKeys.files_failure_restore,
    FileFailureKind.saveFailed ||
    FileFailureKind.cancelled => LocaleKeys.files_failure_save,
  }.tr();
}
