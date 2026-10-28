import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Größen, Größenänderungen und Zeitpunkte von Dateien im Format der
/// App-Sprache.
class FileDisplayTexts {
  const FileDisplayTexts(this._locale, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  factory FileDisplayTexts.of(BuildContext context) {
    return FileDisplayTexts(Localizations.localeOf(context).toLanguageTag());
  }

  final String _locale;
  final DateTime Function() _now;

  static const _units = ['B', 'KB', 'MB', 'GB'];

  /// `840 B`, `8,2 KB`, `12,4 MB` (Basis 1024).
  String size(int bytes) {
    var value = bytes.abs().toDouble();
    var unit = 0;
    while (value >= 1024 && unit < _units.length - 1) {
      value /= 1024;
      unit++;
    }
    final pattern = unit == 0 || value >= 100 ? '0' : '0.#';
    return '${NumberFormat(pattern, _locale).format(value)} ${_units[unit]}';
  }

  /// Änderung zur Vorversion: `+1,2 KB`, `−300 B`; `null` ohne Änderung.
  String? sizeDelta(int deltaBytes) {
    if (deltaBytes == 0) return null;
    return '${deltaBytes > 0 ? '+' : '−'}${size(deltaBytes)}';
  }

  /// Datum und Uhrzeit: `28.10.2026, 13:48`.
  String dateTime(DateTime value) {
    return DateFormat.yMd(_locale).add_Hm().format(value.toLocal());
  }

  /// `gerade eben`, `vor 5 Min.`, `vor 3 Std.`, `gestern, 13:48`, sonst das Datum.
  String relative(DateTime value) {
    final local = value.toLocal();
    final elapsed = _now().difference(local);
    if (elapsed.inMinutes < 1) return LocaleKeys.files_time_just_now.tr();
    if (elapsed.inHours < 1) {
      return _ago(LocaleKeys.files_time_minutes_ago, elapsed.inMinutes);
    }
    if (_isToday(local)) {
      return _ago(LocaleKeys.files_time_hours_ago, elapsed.inHours);
    }
    if (_isYesterday(local)) {
      final time = DateFormat.Hm(_locale).format(local);
      return LocaleKeys.files_time_yesterday.tr(namedArgs: {'time': time});
    }
    return DateFormat.yMd(_locale).format(local);
  }

  String _ago(String key, int count) {
    return key.tr(namedArgs: {'count': '$count'});
  }

  bool _isToday(DateTime value) => DateUtils.isSameDay(value, _now());

  bool _isYesterday(DateTime value) {
    final yesterday = _now().subtract(const Duration(days: 1));
    return DateUtils.isSameDay(value, yesterday);
  }
}
