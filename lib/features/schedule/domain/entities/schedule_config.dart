enum ScheduleKind { once, daily, weekly }

class ScheduleConfig {
  const ScheduleConfig({
    required this.kind,
    required this.timezone,
    this.runAt,
    this.timeOfDay,
    this.weekdays = const [],
  });

  final ScheduleKind kind;
  final String timezone;
  final DateTime? runAt;
  final String? timeOfDay;
  final List<int> weekdays;

  bool get isValid {
    return switch (kind) {
      ScheduleKind.once => runAt != null,
      ScheduleKind.daily => _validTimeOfDay,
      ScheduleKind.weekly => _validTimeOfDay && weekdays.isNotEmpty,
    };
  }

  bool get _validTimeOfDay {
    final value = timeOfDay;
    if (value == null) return false;
    return RegExp(r'^\d{2}:\d{2}$').hasMatch(value);
  }
}
