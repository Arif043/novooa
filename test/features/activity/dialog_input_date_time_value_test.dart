import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/dialog_input_date_time_value.dart';

void main() {
  test('ein Datum wird als YYYY-MM-DD gesendet, ohne Uhrzeit', () {
    final date = DialogInputDateValue.of(DateTime(2026, 3, 7, 23, 59));

    expect(date.toWire(), '2026-03-07');
  });

  test('nur echte Kalendertage werden gelesen', () {
    expect(DialogInputDateValue.tryParse('2026-10-28')?.toWire(), '2026-10-28');
    expect(DialogInputDateValue.tryParse('2026-02-30'), isNull);
    expect(DialogInputDateValue.tryParse('28.10.2026'), isNull);
    expect(DialogInputDateValue.tryParse(null), isNull);
  });

  test('eine Uhrzeit wird zweistellig im 24-Stunden-Format gesendet', () {
    expect(DialogInputTimeValue.of(hour: 9, minute: 5).toWire(), '09:05');
    expect(DialogInputTimeValue.tryParse('23:59')?.toWire(), '23:59');
    expect(DialogInputTimeValue.tryParse('24:00'), isNull);
    expect(DialogInputTimeValue.tryParse('9:30'), isNull);
  });
}
