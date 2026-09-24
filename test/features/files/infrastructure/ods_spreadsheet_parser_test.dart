import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/infrastructure/parsers/ods_spreadsheet_parser.dart';

void main() {
  const parser = OdsSpreadsheetParser();

  test('liest Text-, Zahl- und Bool-Zellen aus einer echten ODS-Struktur', () {
    final bytes = _odsBytes(sheetName: 'Sheet1', contentXml: '''
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:spreadsheet>
      <table:table table:name="Sheet1">
        <table:table-row>
          <table:table-cell office:value-type="string"><text:p>Name</text:p></table:table-cell>
          <table:table-cell office:value-type="float" office:value="42"><text:p>42</text:p></table:table-cell>
          <table:table-cell office:value-type="boolean" office:boolean-value="true"><text:p>WAHR</text:p></table:table-cell>
        </table:table-row>
      </table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>
''');

    final document = parser.parse(bytes);

    expect(document.sheets, hasLength(1));
    final sheet = document.sheets.single;
    expect(sheet.name, 'Sheet1');
    expect(sheet.rows, [
      ['Name', 42, true],
    ]);
  });

  test('wirft bei fremden/korrupten Bytes, statt sie zu verschlucken', () {
    final bytes = Uint8List.fromList(utf8.encode('kein Zip-Archiv'));

    expect(() => parser.parse(bytes), throwsA(isA<Object>()));
  });
}

Uint8List _odsBytes({required String sheetName, required String contentXml}) {
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
