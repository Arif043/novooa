import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/file_name.dart';

void main() {
  test('gültige Namen werden getrimmt übernommen', () {
    expect(FileName.tryParse('  Bericht.pdf ')?.value, 'Bericht.pdf');
  });

  test('leere Namen, Pfadanteile sowie . und .. sind ungültig', () {
    for (final input in ['', '   ', 'a/b.txt', r'a\b.txt', '.', '..']) {
      expect(FileName.tryParse(input), isNull, reason: input);
    }
    expect(FileName.tryParse('x' * 256), isNull);
  });

  test('Basisname und Endung; Punktdateien haben keine Endung', () {
    final report = FileName.tryParse('Bericht.2026.xlsx')!;
    expect(report.baseName, 'Bericht.2026');
    expect(report.extension, '.xlsx');
    expect(FileName.tryParse('.env')!.extension, '');
    expect(FileName.tryParse('README')!.baseName, 'README');
  });

  test('ein Zusatz kommt vor die Endung', () {
    final copy = FileName.tryParse(
      'Rechnungen.xlsx',
    )!.withBaseSuffix(' (Kopie)');
    expect(copy.value, 'Rechnungen (Kopie).xlsx');
  });
}
