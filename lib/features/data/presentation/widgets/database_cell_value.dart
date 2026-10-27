import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

enum DatabaseValueKind {
  number(CupertinoIcons.number),
  boolean(CupertinoIcons.checkmark_square),
  text(CupertinoIcons.textformat),
  structure(CupertinoIcons.chevron_left_slash_chevron_right),
  empty(CupertinoIcons.textformat);

  const DatabaseValueKind(this.icon);

  /// Symbol im Spaltenkopf: zeigt, welche Art Werte die Spalte hält.
  final IconData icon;

  static DatabaseValueKind of(Object? value) => switch (value) {
    null => DatabaseValueKind.empty,
    num() => DatabaseValueKind.number,
    bool() => DatabaseValueKind.boolean,
    Map() || List() => DatabaseValueKind.structure,
    _ => DatabaseValueKind.text,
  };

  /// Art einer Spalte: die gemeinsame Art aller gefüllten Zellen, gemischt gilt als Text.
  static DatabaseValueKind ofColumn(Iterable<Object?> values) {
    final kinds = values.map(of).where((kind) => kind != empty).toSet();
    return kinds.length == 1 ? kinds.single : text;
  }
}

/// Eine Zelle zur Anzeige: Text plus Art — Zahlen rechtsbündig, Wahrheitswerte als Etikett.
class DatabaseCellValue {
  const DatabaseCellValue(
    this.text, [
    this.kind = DatabaseValueKind.text,
    this.isTrue = false,
  ]);

  factory DatabaseCellValue.of(Object? value, String locale) => switch (value) {
    null => DatabaseCellValue('—', DatabaseValueKind.empty),
    num() => DatabaseCellValue(
      NumberFormat.decimalPattern(locale).format(value),
      DatabaseValueKind.number,
    ),
    bool() => DatabaseCellValue(
      value
          ? LocaleKeys.ui_db_value_true.tr()
          : LocaleKeys.ui_db_value_false.tr(),
      DatabaseValueKind.boolean,
    ),
    Map() || List() => DatabaseCellValue(
      LocaleKeys.ui_db_cell_structured.tr(),
      DatabaseValueKind.structure,
    ),
    _ => DatabaseCellValue('$value'),
  };

  final String text;
  final DatabaseValueKind kind;

  /// Für Wahrheitswerte: wahr wird hervorgehoben.
  final bool isTrue;
}
