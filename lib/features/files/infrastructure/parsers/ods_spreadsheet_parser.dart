import 'dart:typed_data';

import 'package:table_parser/table_parser.dart';

import '../../domain/entities/spreadsheet_document.dart';

/// Adapts `package:table_parser`'s ODS decoder to the pure-Dart
/// [SpreadsheetDocument] domain shape — analogous to the `*_document_mapper`
/// classes translating JSON into domain entities elsewhere in this feature.
///
/// Deliberately not a `Repository`: parsing bytes into a value object is a
/// stateless, side-effect-free transformation, not a swappable data source.
///
/// Lets any parsing failure (e.g. `UnsupportedError` for a file that isn't a
/// valid ODS/XLSX archive) propagate unchanged — callers decide how to
/// present that as an error state.
class OdsSpreadsheetParser {
  const OdsSpreadsheetParser();

  SpreadsheetDocument parse(Uint8List bytes) {
    final decoder = TableParser.decodeBytes(bytes);
    final sheets = decoder.tables.entries
        .map(
          (entry) => SpreadsheetSheet(
            name: entry.key,
            rows: _rowsFrom(entry.value),
          ),
        )
        .toList(growable: false);
    return SpreadsheetDocument(sheets: sheets);
  }

  List<List<Object?>> _rowsFrom(TableSheet sheet) {
    return sheet.rows
        .map((row) => row.cast<Object?>())
        .toList(growable: false);
  }
}
