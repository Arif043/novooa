import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// So viele Felder nennt die Vorschau einer Sammlung, der Rest erscheint als „+n“.
const _previewFieldCount = 4;

String databaseCollectionCount(int count) => count == 1
    ? LocaleKeys.ui_db_collections_one.tr()
    : LocaleKeys.ui_db_collections_other.tr(namedArgs: {'count': '$count'});

String databaseRecordCount(int count) => count == 1
    ? LocaleKeys.ui_db_records_one.tr()
    : LocaleKeys.ui_db_records_other.tr(namedArgs: {'count': '$count'});

String databaseFieldPreview(List<String> fields) {
  if (fields.isEmpty) return LocaleKeys.ui_db_no_fields.tr();
  final shown = fields.take(_previewFieldCount).join(' · ');
  final hidden = fields.length - _previewFieldCount;
  return hidden > 0 ? '$shown · +$hidden' : shown;
}

/// „geändert vor 2 Std.“ — ab einer Woche mit Datum in der Sprache der Oberfläche.
String databaseChangedLabel(DateTime changedAt, DateTime now, String locale) {
  final age = now.difference(changedAt);
  return switch (age) {
    _ when age.inMinutes < 1 => LocaleKeys.ui_db_changed_just_now.tr(),
    _ when age.inHours < 1 => _changed(
      LocaleKeys.ui_db_changed_minutes,
      age.inMinutes,
    ),
    _ when age.inDays < 1 => _changed(
      LocaleKeys.ui_db_changed_hours,
      age.inHours,
    ),
    _ when age.inDays < 7 => _changed(
      LocaleKeys.ui_db_changed_days,
      age.inDays,
    ),
    _ => LocaleKeys.ui_db_changed_on.tr(
      namedArgs: {'date': DateFormat.yMd(locale).format(changedAt.toLocal())},
    ),
  };
}

String _changed(String key, int count) =>
    key.tr(namedArgs: {'count': '$count'});
