import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/presentation/widgets/content/spreadsheet_content_view.dart';

void main() {
  Future<void> pump(WidgetTester tester, Uint8List bytes) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SpreadsheetContentView(bytes: bytes))),
    );
  }

  testWidgets('zeigt Zellinhalte einer gültigen ODS-Tabelle', (tester) async {
    await pump(
      tester,
      _odsBytes('''
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:spreadsheet>
      <table:table table:name="Sheet1">
        <table:table-row>
          <table:table-cell office:value-type="string"><text:p>Kunde</text:p></table:table-cell>
        </table:table-row>
      </table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>
'''),
    );

    expect(find.text('Kunde'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets('zeigt einen Fehler für korrupte Bytes', (tester) async {
    await pump(tester, Uint8List.fromList(utf8.encode('kein Zip-Archiv')));

    expect(find.text('Tabelle konnte nicht gelesen werden.'), findsOneWidget);
  });

  testWidgets('zeigt einen Leer-Zustand ohne Zeilen', (tester) async {
    await pump(
      tester,
      _odsBytes('''
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:spreadsheet>
      <table:table table:name="Leer"></table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>
'''),
    );

    expect(find.text('Diese Tabelle enthält keine Daten.'), findsOneWidget);
  });

  testWidgets(
    'zeigt den Leer-Zustand statt abzustürzen, wenn ein leeres Blatt per '
    'Sheet-Selector ausgewählt wird (Regressionstest)',
    (tester) async {
      await pump(
        tester,
        _odsBytes('''
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:spreadsheet>
      <table:table table:name="Tabelle1">
        <table:table-row>
          <table:table-cell office:value-type="string"><text:p>Kunde</text:p></table:table-cell>
        </table:table-row>
      </table:table>
      <table:table table:name="Tabelle2"></table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>
'''),
      );
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

Uint8List _odsBytes(String contentXml) {
  final archive = Archive();
  final mimetype = utf8.encode(
    'application/vnd.oasis.opendocument.spreadsheet',
  );
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype));
  final content = utf8.encode(contentXml);
  archive.addFile(ArchiveFile('content.xml', content.length, content));
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}
