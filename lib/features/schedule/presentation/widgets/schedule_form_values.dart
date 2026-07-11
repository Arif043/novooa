import 'package:flutter/material.dart';

import '../../domain/entities/schedule_config.dart';

class ScheduleFormValues {
  const ScheduleFormValues();

  ScheduleConfig config({
    required ScheduleKind kind,
    required DateTime date,
    required TimeOfDay time,
    required List<WeeklyTimeSlot> slots,
  }) {
    return switch (kind) {
      ScheduleKind.once => ScheduleConfig(
        kind: kind,
        timezone: 'Europe/Berlin',
        runAt: runAt(date, time),
      ),
      ScheduleKind.daily => ScheduleConfig(
        kind: kind,
        timezone: 'Europe/Berlin',
        timeOfDay: timeLabel(time),
      ),
      ScheduleKind.weekly => ScheduleConfig(
        kind: kind,
        timezone: 'Europe/Berlin',
        slots: slots,
      ),
    };
  }

  DateTime runAt(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String timeLabel(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
