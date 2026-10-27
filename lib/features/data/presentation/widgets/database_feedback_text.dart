import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/data_failure.dart';
import '../cubits/database_actions_state.dart';

/// Übersetzt Rückmeldungen der Datenbank-Cubits; die Cubits kennen keine Texte.
String databaseNoticeText(DatabaseNotice notice) {
  final args = {'name': notice.name ?? '', 'count': '${notice.count ?? 0}'};
  return switch (notice.kind) {
    DatabaseNoticeKind.collectionCreated => LocaleKeys.ui_db_notice_created.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.collectionRenamed => LocaleKeys.ui_db_notice_renamed.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.collectionDeleted => LocaleKeys.ui_db_notice_deleted.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.collectionCleared => LocaleKeys.ui_db_notice_cleared.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.recordsDeleted =>
      LocaleKeys.ui_db_notice_records_deleted.tr(namedArgs: args),
    DatabaseNoticeKind.recordsImported => LocaleKeys.ui_db_notice_imported.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.exported => LocaleKeys.ui_db_notice_exported.tr(
      namedArgs: args,
    ),
    DatabaseNoticeKind.failed => dataFailureText(
      notice.failure ?? const DataFailure(DataFailureKind.failed),
    ),
  };
}

String dataFailureText(DataFailure failure) => switch (failure.kind) {
  DataFailureKind.nameTaken => LocaleKeys.ui_db_failure_name_taken.tr(),
  DataFailureKind.notFound => LocaleKeys.ui_db_failure_not_found.tr(),
  DataFailureKind.tooLarge => LocaleKeys.ui_db_failure_too_large.tr(),
  DataFailureKind.invalidFile => LocaleKeys.ui_db_failure_invalid_file.tr(),
  DataFailureKind.cancelled ||
  DataFailureKind.failed => LocaleKeys.ui_db_failure_generic.tr(),
};
