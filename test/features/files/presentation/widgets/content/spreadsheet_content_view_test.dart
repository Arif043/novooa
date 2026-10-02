import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/presentation/widgets/content/spreadsheet_content_view.dart';

void main() {
  Future<void> pump(WidgetTester tester, Uint8List bytes) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SpreadsheetContentView(bytes: bytes)),
      ),
    );
    // Parsing now runs on a real background isolate (`compute`) — a plain
    // `pump()`/`pumpAndSettle()` can't drive that (they only advance
    // fake/animation time, and the loading spinner's own indeterminate
    // animation makes `pumpAndSettle` time out besides). `runAsync` steps
    // outside the fake test zone so the real isolate round-trip can
    // actually finish, then a normal `pump()` applies the resulting
    // `setState`.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }

  testWidgets(
    'zeigt einen Ladeindikator, während die Datei im Hintergrund geparst '
    'wird',
    (tester) async {
      final workbook = excel_lib.Excel.createExcel();
      workbook['Sheet1'].cell(_at(0, 0)).value = excel_lib.TextCellValue(
        'Kunde',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpreadsheetContentView(bytes: _encode(workbook)),
          ),
        ),
      );
      // Absichtlich kein `runAsync`/Verzögerung hier — direkt nach dem
      // ersten Frame läuft der Parse-Isolate noch, der Ladezustand muss
      // sofort sichtbar sein.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Kunde'), findsNothing);
    },
  );

  testWidgets('zeigt Zellinhalte einer gültigen XLSX-Tabelle', (tester) async {
    final workbook = excel_lib.Excel.createExcel();
    workbook['Sheet1'].cell(_at(0, 0)).value = excel_lib.TextCellValue('Kunde');

    await pump(tester, _encode(workbook));

    expect(find.text('Kunde'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets(
    'zeigt fett formatierte Zellen aus der Datei und E-Mail-Zellen als Link',
    (tester) async {
      final workbook = excel_lib.Excel.createExcel();
      final sheet = workbook['Sheet1'];
      sheet.cell(_at(0, 0))
        ..value = excel_lib.TextCellValue('Vorname')
        ..cellStyle = excel_lib.CellStyle(bold: true);
      sheet.cell(_at(1, 0))
        ..value = excel_lib.TextCellValue('email')
        ..cellStyle = excel_lib.CellStyle(bold: true);
      sheet.cell(_at(0, 1)).value = excel_lib.TextCellValue('Christian');
      sheet.cell(_at(1, 1)).value = excel_lib.TextCellValue(
        'c.mustermann@muster.at',
      );

      await pump(tester, _encode(workbook));

      final headerCell = tester.widget<Text>(find.text('Vorname'));
      expect(headerCell.style?.fontWeight, FontWeight.bold);

      final plainDataCell = tester.widget<Text>(find.text('Christian'));
      expect(plainDataCell.style?.fontWeight, isNot(FontWeight.bold));
      expect(plainDataCell.style?.decoration, isNot(TextDecoration.underline));

      final emailFinder = find.text('c.mustermann@muster.at');
      final emailCell = tester.widget<Text>(emailFinder);
      expect(emailCell.style?.decoration, TextDecoration.underline);
      expect(
        find.ancestor(of: emailFinder, matching: find.byType(InkWell)),
        findsOneWidget,
      );
    },
  );

  testWidgets('zeigt Schrift- und Hintergrundfarbe aus der Datei', (
    tester,
  ) async {
    final workbook = excel_lib.Excel.createExcel();
    workbook['Sheet1'].cell(_at(0, 0))
      ..value = excel_lib.TextCellValue('Wichtig')
      ..cellStyle = excel_lib.CellStyle(
        fontColorHex: excel_lib.ExcelColor.red,
        backgroundColorHex: excel_lib.ExcelColor.yellow,
      );

    await pump(tester, _encode(workbook));

    final textFinder = find.text('Wichtig');
    final textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.style?.color, Color(excel_lib.ExcelColor.red.colorInt));

    final container = tester.widget<Container>(
      find.ancestor(of: textFinder, matching: find.byType(Container)).first,
    );
    expect(container.color, Color(excel_lib.ExcelColor.yellow.colorInt));
  });

  testWidgets('zeigt einen Fehler für korrupte Bytes', (tester) async {
    await pump(tester, Uint8List.fromList(utf8.encode('kein Zip-Archiv')));

    expect(find.text('Tabelle konnte nicht gelesen werden.'), findsOneWidget);
  });

  testWidgets('zeigt einen Leer-Zustand ohne Zeilen', (tester) async {
    final workbook = excel_lib.Excel.createExcel();
    workbook.rename('Sheet1', 'Leer');

    await pump(tester, _encode(workbook));

    expect(find.text('Diese Tabelle enthält keine Daten.'), findsOneWidget);
  });

  testWidgets(
    'zeigt den Leer-Zustand statt abzustürzen, wenn ein leeres Blatt per '
    'Sheet-Selector ausgewählt wird (Regressionstest)',
    (tester) async {
      final workbook = excel_lib.Excel.createExcel();
      workbook.rename('Sheet1', 'Tabelle1');
      workbook['Tabelle1'].cell(_at(0, 0)).value = excel_lib.TextCellValue(
        'Kunde',
      );
      workbook['Tabelle2']; // touched, but left without any cell

      await pump(tester, _encode(workbook));
      expect(find.text('Kunde'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tabelle2').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Diese Tabelle enthält keine Daten.'), findsOneWidget);
      expect(find.byType(Table), findsNothing);
    },
  );
}

excel_lib.CellIndex _at(int columnIndex, int rowIndex) =>
    excel_lib.CellIndex.indexByColumnRow(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
    );

Uint8List _encode(excel_lib.Excel workbook) =>
    Uint8List.fromList(workbook.encode()!);
