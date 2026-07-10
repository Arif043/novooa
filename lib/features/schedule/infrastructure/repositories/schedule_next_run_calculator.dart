import '../../domain/entities/schedule_config.dart';

class ScheduleNextRunCalculator {
  const ScheduleNextRunCalculator();

  DateTime? call(ScheduleConfig config, DateTime now) {
    return switch (config.kind) {
      ScheduleKind.once => _futureOnce(config, now),
      ScheduleKind.daily => _daily(config, now),
      ScheduleKind.weekly => _weekly(config, now),
    };
  }

  DateTime? _futureOnce(ScheduleConfig config, DateTime now) {
    final runAt = config.runAt;
    if (runAt == null) return null;
    return runAt.isAfter(now) ? runAt : null;
  }

  DateTime? _daily(ScheduleConfig config, DateTime now) {
    final time = _timeParts(config.timeOfDay);
    if (time == null) return null;
    final today = _atTime(now, time);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  DateTime? _weekly(ScheduleConfig config, DateTime now) {
    final time = _timeParts(config.timeOfDay);
    if (time == null || config.weekdays.isEmpty) return null;
    for (var offset = 0; offset < 8; offset++) {
      final date = now.add(Duration(days: offset));
      if (!config.weekdays.contains(date.weekday)) continue;
      final candidate = _atTime(date, time);
      if (candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  DateTime _atTime(DateTime date, ({int hour, int minute}) time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  ({int hour, int minute})? _timeParts(String? value) {
    if (value == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
      return null;
    }
    return (
      hour: int.parse(value.substring(0, 2)),
      minute: int.parse(value.substring(3, 5)),
    );
  }
}
