enum ScheduleKind { once, daily, weekly }

class WeeklyTimeSlot {
  const WeeklyTimeSlot({required this.weekday, required this.timeOfDay});

  final int weekday;
  final String timeOfDay;

  bool get isValid {
    return weekday >= DateTime.monday &&
        weekday <= DateTime.sunday &&
        _validTimeOfDay(timeOfDay);
  }

  static bool _validTimeOfDay(String value) {
    return RegExp(r'^\d{2}:\d{2}$').hasMatch(value);
  }
}

class ScheduleConfig {
  const ScheduleConfig({
    required this.kind,
    required this.timezone,
    this.runAt,
    this.timeOfDay,
    this.weekdays = const [],
    this.slots = const [],
  });

  final ScheduleKind kind;
  final String timezone;
  final DateTime? runAt;
  final String? timeOfDay;
  final List<int> weekdays;
  final List<WeeklyTimeSlot> slots;

  bool get isValid {
    return switch (kind) {
      ScheduleKind.once => runAt != null,
      ScheduleKind.daily => _validTimeOfDay,
      ScheduleKind.weekly =>
        slots.isNotEmpty && slots.every((slot) => slot.isValid),
    };
  }

  bool get _validTimeOfDay {
    final value = timeOfDay;
    if (value == null) return false;
    return RegExp(r'^\d{2}:\d{2}$').hasMatch(value);
  }
}
