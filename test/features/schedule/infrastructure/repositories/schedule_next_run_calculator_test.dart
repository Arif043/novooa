import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/schedule/domain/entities/schedule_config.dart';
import 'package:syscat2/features/schedule/infrastructure/repositories/schedule_next_run_calculator.dart';

void main() {
  const calculator = ScheduleNextRunCalculator();

  test('berechnet taegliche naechste Ausfuehrung fuer heute', () {
    final nextRun = calculator(
      const ScheduleConfig(
        kind: ScheduleKind.daily,
        timezone: 'Europe/Berlin',
        timeOfDay: '09:30',
      ),
      DateTime(2026, 7, 10, 8),
    );

    expect(nextRun, DateTime(2026, 7, 10, 9, 30));
  });

  test('berechnet taegliche naechste Ausfuehrung fuer morgen', () {
    final nextRun = calculator(
      const ScheduleConfig(
        kind: ScheduleKind.daily,
        timezone: 'Europe/Berlin',
        timeOfDay: '09:30',
      ),
      DateTime(2026, 7, 10, 10),
    );

    expect(nextRun, DateTime(2026, 7, 11, 9, 30));
  });

  test('berechnet woechentliche naechste Ausfuehrung', () {
    final nextRun = calculator(
      const ScheduleConfig(
        kind: ScheduleKind.weekly,
        timezone: 'Europe/Berlin',
        timeOfDay: '07:15',
        weekdays: [DateTime.monday],
      ),
      DateTime(2026, 7, 10, 10),
    );

    expect(nextRun, DateTime(2026, 7, 13, 7, 15));
  });

  test('berechnet naechsten frei gewaehlten Wochenzeitpunkt', () {
    final nextRun = calculator(
      const ScheduleConfig(
        kind: ScheduleKind.weekly,
        timezone: 'Europe/Berlin',
        slots: [
          WeeklyTimeSlot(weekday: DateTime.friday, timeOfDay: '14:30'),
          WeeklyTimeSlot(weekday: DateTime.monday, timeOfDay: '08:00'),
        ],
      ),
      DateTime(2026, 7, 10, 10),
    );

    expect(nextRun, DateTime(2026, 7, 10, 14, 30));
  });

  test('einmaliger Trigger in der Vergangenheit ist nicht mehr faellig', () {
    final nextRun = calculator(
      ScheduleConfig(
        kind: ScheduleKind.once,
        timezone: 'Europe/Berlin',
        runAt: DateTime(2026, 7, 10, 9),
      ),
      DateTime(2026, 7, 10, 10),
    );

    expect(nextRun, isNull);
  });
}
