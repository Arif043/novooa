/// An RGBA color read from a spreadsheet cell's own font/fill styling.
///
/// Pure Dart on purpose — no `dart:ui`/Flutter `Color` dependency in the
/// domain layer. [argb] packs channels the same way Flutter's `Color` does
/// (`0xAARRGGBB`), so the presentation layer can build one directly via
/// `Color(cell.fontColor!.argb)`.
class SpreadsheetColor {
  const SpreadsheetColor(this.argb);

  final int argb;
}

/// One cell of a parsed spreadsheet sheet.
///
/// [value] is one of `null` (empty), `num`, `bool` or `String` — the full
/// set of types a spreadsheet cell can hold once dates/times/formulas have
/// already been normalized to their string representation upstream.
/// [isBold], [fontColor] and [backgroundColor] reflect the cell's own style
/// from the source file, not a display convention imposed by the viewer.
class SpreadsheetCell {
  const SpreadsheetCell({
    this.value,
    this.isBold = false,
    this.fontColor,
    this.backgroundColor,
  });

  final Object? value;
  final bool isBold;
  final SpreadsheetColor? fontColor;
  final SpreadsheetColor? backgroundColor;
}

/// One sheet of a parsed spreadsheet document. Every row has the same
/// length ([SpreadsheetSheet.columnCount]).
class SpreadsheetSheet {
  const SpreadsheetSheet({required this.name, required this.rows});

  final String name;
  final List<List<SpreadsheetCell>> rows;

  int get columnCount => rows.isEmpty ? 0 : rows.first.length;

  bool get isEmpty => rows.isEmpty || columnCount == 0;
}

/// A parsed spreadsheet document — pure Dart, independent of whichever
/// third-party library did the actual file-format parsing (see
/// `XlsxSpreadsheetParser` in the infrastructure layer).
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

final RegExp _emailPattern = RegExp(
  r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
);

/// A `mailto:`/web [Uri] to open for [value] if its text looks like an email
/// address or an absolute web URL, or `null` otherwise.
///
/// The `excel` package doesn't expose hyperlink relationships (`xl/
/// worksheets/_rels/*.rels`) through its public API — this heuristic lets
/// the viewer still present recognisable contact/reference data (e.g. an
/// "email" column) as clickable links.
Uri? spreadsheetCellLink(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (_emailPattern.hasMatch(trimmed)) {
    return Uri(scheme: 'mailto', path: trimmed);
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return uri;
  }
  return null;
}
