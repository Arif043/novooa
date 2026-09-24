import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/infrastructure/parsers/xlsx_spreadsheet_parser.dart';

void main() {
  const parser = XlsxSpreadsheetParser();

  test(
    'liest Text-, Zahl-, Bool-Zellen und Fettformatierung aus einer echten '
    'XLSX-Struktur',
    () {
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.cell(_at(0, 0))
        ..value = excel_lib.TextCellValue('Name')
        ..cellStyle = excel_lib.CellStyle(bold: true);
      sheet.cell(_at(1, 0)).value = excel_lib.IntCellValue(42);
      sheet.cell(_at(2, 0)).value = excel_lib.BoolCellValue(true);
      final bytes = Uint8List.fromList(workbook.encode()!);

      final document = parser.parse(bytes);

      expect(document.sheets, hasLength(1));
      final resultSheet = document.sheets.single;
      expect(resultSheet.name, 'Sheet1');
      final row = resultSheet.rows.single;
      expect(row.map((cell) => cell.value), ['Name', 42, true]);
      expect(row.map((cell) => cell.isBold), [true, false, false]);
    },
  );

  test(
    'liest Schrift- und Hintergrundfarbe, aber ignoriert Default-Schwarz '
    'und leere Füllung',
    () {
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.cell(_at(0, 0))
        ..value = excel_lib.TextCellValue('Wichtig')
        ..cellStyle = excel_lib.CellStyle(
          fontColorHex: excel_lib.ExcelColor.red,
          backgroundColorHex: excel_lib.ExcelColor.yellow,
        );
      sheet.cell(_at(1, 0)).value = excel_lib.TextCellValue('Normal');
      final bytes = Uint8List.fromList(workbook.encode()!);

      final document = parser.parse(bytes);

      final row = document.sheets.single.rows.single;
      expect(row[0].fontColor?.argb, excel_lib.ExcelColor.red.colorInt);
      expect(row[0].backgroundColor?.argb, excel_lib.ExcelColor.yellow.colorInt);
      expect(row[1].fontColor, isNull);
      expect(row[1].backgroundColor, isNull);
    },
  );

  test(
    'schneidet nachgestellte, nur gestylte, ansonsten leere Zeilen/Spalten ab',
    () {
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.cell(_at(0, 0)).value = excel_lib.TextCellValue('Kunde');
      // Touching a far-away cell without a value simulates a real file's
      // "used range" being padded beyond the actually filled data (e.g. a
      // once-selected, now-empty formatting range) — `excel` reports this
      // as part of `maxRows`/`maxColumns`, so our parser must trim it away.
      sheet.cell(_at(5, 5));
      final bytes = Uint8List.fromList(workbook.encode()!);

      final document = parser.parse(bytes);

      final resultSheet = document.sheets.single;
      expect(resultSheet.rows, hasLength(1));
      expect(resultSheet.columnCount, 1);
      expect(resultSheet.rows.single.single.value, 'Kunde');
    },
  );

  test('wirft bei fremden/korrupten Bytes, statt sie zu verschlucken', () {
    final bytes = Uint8List.fromList(utf8.encode('kein Zip-Archiv'));

    expect(() => parser.parse(bytes), throwsA(isA<Object>()));
  });
}

excel_lib.CellIndex _at(int columnIndex, int rowIndex) =>
    excel_lib.CellIndex.indexByColumnRow(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
    );
