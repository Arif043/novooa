import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/features/files/presentation/localization/file_display_texts.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  final now = DateTime(2026, 10, 28, 14);
  final texts = FileDisplayTexts('de', now: () => now);

  test('Größen in der passenden Einheit mit deutschem Komma', () {
    expect(texts.size(840), '840 B');
    expect(texts.size(8396), '8,2 KB');
    expect(texts.size(5 * 1024 * 1024), '5 MB');
  });

  test('Größenänderungen mit Vorzeichen, ohne Änderung keine', () {
    expect(texts.sizeDelta(1024), '+1 KB');
    expect(texts.sizeDelta(-300), '−300 B');
    expect(texts.sizeDelta(0), isNull);
  });

  test('jüngere Zeitpunkte relativ, ältere als Datum', () {
    expect(
      texts.relative(now.subtract(const Duration(seconds: 20))),
      'gerade eben',
    );
    expect(
      texts.relative(now.subtract(const Duration(minutes: 5))),
      'vor 5 Min.',
    );
    expect(
      texts.relative(now.subtract(const Duration(hours: 3))),
      'vor 3 Std.',
    );
    expect(texts.relative(DateTime(2026, 10, 27, 9, 5)), 'gestern, 09:05');
    expect(texts.relative(DateTime(2026, 10, 20, 9)), '20.10.2026');
  });
}
