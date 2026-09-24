import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/file_content_kind.dart';

void main() {
  const classifier = FileContentKindClassifier();

  test('klassifiziert XLSX-Dokumente als spreadsheet', () {
    expect(
      classifier.classify(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
      FileContentKind.spreadsheet,
    );
  });

  test(
    'erkennt .xlsx am Dateinamen, wenn der Content-Type nur octet-stream ist',
    () {
      expect(
        classifier.classify(
          'application/octet-stream',
          fileName: 'bericht.xlsx',
        ),
        FileContentKind.spreadsheet,
      );
      expect(
        classifier.classify(
          'application/octet-stream',
          fileName: 'bericht.pdf',
        ),
        FileContentKind.unsupported,
      );
      expect(
        classifier.classify('application/octet-stream'),
        FileContentKind.unsupported,
      );
    },
  );

  test('bestehende Klassifikationen bleiben unverändert', () {
    expect(classifier.classify('text/plain'), FileContentKind.text);
    expect(classifier.classify('application/json'), FileContentKind.text);
    expect(classifier.classify('image/png'), FileContentKind.image);
    expect(classifier.classify('application/pdf'), FileContentKind.pdf);
    expect(
      classifier.classify('application/octet-stream'),
      FileContentKind.unsupported,
    );
  });
}
