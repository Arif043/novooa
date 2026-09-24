import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/spreadsheet_document.dart';

void main() {
  test('ein Blatt ohne Zeilen gilt als leer', () {
    const sheet = SpreadsheetSheet(name: 'Leer', rows: []);

    expect(sheet.isEmpty, isTrue);
    expect(sheet.columnCount, 0);
  });

  test(
    'ein Blatt mit Zeilen, aber null Spalten gilt ebenfalls als leer '
    '(table_parser liefert für komplett inhaltslose Blätter genau das)',
    () {
      const sheet = SpreadsheetSheet(name: 'Tabelle2', rows: [[], []]);

      expect(sheet.isEmpty, isTrue);
      expect(sheet.columnCount, 0);
    },
  );

  test('ein Blatt mit tatsächlichen Zellen gilt nicht als leer', () {
    const sheet = SpreadsheetSheet(
      name: 'Sheet1',
      rows: [
        ['Name', 42],
      ],
    );

    expect(sheet.isEmpty, isFalse);
    expect(sheet.columnCount, 2);
  });

  test('das Dokument gilt nur als leer, wenn ausnahmslos alle Blätter leer sind', () {
    const document = SpreadsheetDocument(
      sheets: [
        SpreadsheetSheet(
          name: 'Sheet1',
          rows: [
            ['Wert'],
          ],
        ),
        SpreadsheetSheet(name: 'Sheet2', rows: []),
      ],
    );

    expect(document.isEmpty, isFalse);
  });

  test('spreadsheetColumnLabel liefert Excel-übliche Spaltenbuchstaben', () {
    expect(spreadsheetColumnLabel(0), 'A');
    expect(spreadsheetColumnLabel(25), 'Z');
    expect(spreadsheetColumnLabel(26), 'AA');
    expect(spreadsheetColumnLabel(27), 'AB');
    expect(spreadsheetColumnLabel(51), 'AZ');
    expect(spreadsheetColumnLabel(701), 'ZZ');
    expect(spreadsheetColumnLabel(702), 'AAA');
  });
}
