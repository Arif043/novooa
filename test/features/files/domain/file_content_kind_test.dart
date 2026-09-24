import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/file_content_kind.dart';

void main() {
  const classifier = FileContentKindClassifier();

  test('klassifiziert ODS-Dokumente als spreadsheet', () {
    expect(
      classifier.classify('application/vnd.oasis.opendocument.spreadsheet'),
      FileContentKind.spreadsheet,
    );
  });

  test(
    'erkennt .ods am Dateinamen, wenn der Content-Type nur octet-stream ist',
    () {
      expect(
        classifier.classify(
          'application/octet-stream',
          fileName: 'bericht.ods',
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
