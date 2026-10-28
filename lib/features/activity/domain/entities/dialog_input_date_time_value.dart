/// Wire-Format der Datums- und Uhrzeitfelder eines Formulars: ein Kalendertag
/// `YYYY-MM-DD` und eine Uhrzeit `HH:mm`, beide ohne Zeitzone — die Person
/// meint einen Tag und eine Uhrzeit, keinen Zeitpunkt.
class DialogInputDateValue {
  const DialogInputDateValue._(this.year, this.month, this.day);

  factory DialogInputDateValue.of(DateTime date) {
    return DialogInputDateValue._(date.year, date.month, date.day);
  }

  final int year;
  final int month;
  final int day;

  static DialogInputDateValue? tryParse(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final [year, month, day] = [1, 2, 3].map((group) {
      return int.parse(match.group(group)!);
    }).toList();
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return DialogInputDateValue._(year, month, day);
  }

  DateTime toDateTime() => DateTime(year, month, day);

  String toWire() => '${_padded(year, 4)}-${_padded(month)}-${_padded(day)}';
}

class DialogInputTimeValue {
  const DialogInputTimeValue._(this.hour, this.minute);

  factory DialogInputTimeValue.of({required int hour, required int minute}) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    return DialogInputTimeValue._(hour, minute);
  }

  final int hour;
  final int minute;

  static DialogInputTimeValue? tryParse(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) return null;
    return DialogInputTimeValue._(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  String toWire() => '${_padded(hour)}:${_padded(minute)}';
}

String _padded(int value, [int width = 2]) {
  return value.toString().padLeft(width, '0');
}
