import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;

import '../../domain/entities/spreadsheet_document.dart';

/// Adapts `package:excel`'s XLSX decoder to the pure-Dart
/// [SpreadsheetDocument] domain shape — analogous to the `*_document_mapper`
/// classes translating JSON into domain entities elsewhere in this feature.
///
/// Deliberately not a `Repository`: parsing bytes into a value object is a
/// stateless, side-effect-free transformation, not a swappable data source.
///
/// Lets any parsing failure (e.g. `UnsupportedError` for a file that isn't a
/// valid XLSX archive) propagate unchanged — callers decide how to present
/// that as an error state.
class XlsxSpreadsheetParser {
  const XlsxSpreadsheetParser();

  SpreadsheetDocument parse(Uint8List bytes) {
    final workbook = excel_lib.Excel.decodeBytes(bytes);
    final sheets = workbook.tables.entries
        .map((entry) => _sheetFrom(entry.key, entry.value))
        .toList(growable: false);
    return SpreadsheetDocument(sheets: sheets);
  }

  SpreadsheetSheet _sheetFrom(String name, excel_lib.Sheet sheet) {
    final rows = [
      for (final row in sheet.rows)
        [for (final cell in row) _cellFrom(cell)],
    ];
    return SpreadsheetSheet(name: name, rows: _trimTrailingEmpty(rows));
  }

  SpreadsheetCell _cellFrom(excel_lib.Data? cell) {
    final style = cell?.cellStyle;
    return SpreadsheetCell(
      value: _valueFrom(cell?.value),
      isBold: style?.isBold ?? false,
      // `excel` defaults every untouched cell's font to black — without
      // this exclusion, plain/unstyled cells would force black text even
      // in a dark theme. A background left at `ExcelColor.none` (no fill)
      // is excluded the same way so the grid's own surface shows through.
      fontColor: _colorFrom(style?.fontColor, excludeDefaultBlack: true),
      backgroundColor: _colorFrom(style?.backgroundColor),
    );
  }

  SpreadsheetColor? _colorFrom(
    excel_lib.ExcelColor? color, {
    bool excludeDefaultBlack = false,
  }) {
    if (color == null) return null;
    if (color.colorHex == excel_lib.ExcelColor.none.colorHex) return null;
    if (excludeDefaultBlack &&
        color.colorHex == excel_lib.ExcelColor.black.colorHex) {
      return null;
    }
    return SpreadsheetColor(color.colorInt);
  }

  /// Unlike the previous ODS parser (`table_parser`, which trimmed trailing
  /// empty rows/cells itself), `excel` reports a sheet's raw "used range" —
  /// which real-world files sometimes pad with empty, merely-styled cells.
  /// Trim those trailing rows/columns so the grid matches what a user
  /// actually filled in.
  List<List<SpreadsheetCell>> _trimTrailingEmpty(
    List<List<SpreadsheetCell>> rows,
  ) {
    return _trimTrailingEmptyColumns(_trimTrailingEmptyRows(rows));
  }

  List<List<SpreadsheetCell>> _trimTrailingEmptyRows(
    List<List<SpreadsheetCell>> rows,
  ) {
    var end = rows.length;
    while (end > 0 && rows[end - 1].every((cell) => cell.value == null)) {
      end--;
    }
    return rows.sublist(0, end);
  }

  List<List<SpreadsheetCell>> _trimTrailingEmptyColumns(
    List<List<SpreadsheetCell>> rows,
  ) {
    if (rows.isEmpty) return rows;
    var columnCount = rows.first.length;
    while (
        columnCount > 0 &&
        rows.every((row) => row[columnCount - 1].value == null)) {
      columnCount--;
    }
    return [for (final row in rows) row.sublist(0, columnCount)];
  }

  // `DateCellValue`/`DateTimeCellValue`/`TimeCellValue` all fall into the
  // `_` branch — each already formats itself sensibly via `toString()`
  // (ISO 8601 for dates, `HH:MM:SS` for times), so there's nothing
  // format-specific left to do beyond calling it.
  Object? _valueFrom(excel_lib.CellValue? value) => switch (value) {
    null => null,
    excel_lib.TextCellValue text => text.value.toString(),
    excel_lib.IntCellValue v => v.value,
    excel_lib.DoubleCellValue v => v.value,
    excel_lib.BoolCellValue v => v.value,
    excel_lib.FormulaCellValue v => v.formula,
    _ => value.toString(),
  };
}
