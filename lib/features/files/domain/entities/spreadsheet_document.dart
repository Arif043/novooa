/// One sheet of a parsed spreadsheet document.
///
/// A cell value is one of `null` (empty), `num`, `bool` or `String` — the
/// full set of types a spreadsheet cell can hold once dates/times have
/// already been normalized to their string representation upstream. Every
/// row has the same length ([SpreadsheetSheet.columnCount]).
class SpreadsheetSheet {
  const SpreadsheetSheet({required this.name, required this.rows});

  final String name;
  final List<List<Object?>> rows;

  int get columnCount => rows.isEmpty ? 0 : rows.first.length;

  /// True when there are no rows at all, or — a sheet with only empty rows,
  /// which `table_parser` represents as row entries clamped to zero
  /// columns rather than an empty row list — no cell would have any
  /// content to show either way.
  bool get isEmpty => rows.isEmpty || columnCount == 0;
}

/// A parsed spreadsheet document — pure Dart, independent of whichever
/// third-party library did the actual file-format parsing (see
/// `OdsSpreadsheetParser` in the infrastructure layer).
class SpreadsheetDocument {
  const SpreadsheetDocument({required this.sheets});

  final List<SpreadsheetSheet> sheets;

  bool get isEmpty => sheets.every((sheet) => sheet.isEmpty);
}

/// Converts a zero-based column index into its spreadsheet letter label
/// (0 → 'A', 25 → 'Z', 26 → 'AA', …) — the bijective base-26 numbering every
/// spreadsheet application uses for column headers.
String spreadsheetColumnLabel(int index) {
  var label = '';
  var remaining = index;
  do {
    label = String.fromCharCode(65 + remaining % 26) + label;
    remaining = remaining ~/ 26 - 1;
  } while (remaining >= 0);
  return label;
}
