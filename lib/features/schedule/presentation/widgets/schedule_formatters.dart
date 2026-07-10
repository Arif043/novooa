import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';

String scheduleLabel(ScheduleConfig config) {
  return switch (config.kind) {
    ScheduleKind.once => 'Einmalig am ${dateTimeLabel(config.runAt)}',
    ScheduleKind.daily => 'Täglich um ${config.timeOfDay}',
    ScheduleKind.weekly =>
      'Wöchentlich ${weekdayLabels(config.weekdays)} um ${config.timeOfDay}',
  };
}

String triggerStatusLabel(TaskTrigger trigger) {
  if (!trigger.enabled) return 'Pausiert';
  if (trigger.nextRunAt == null) return 'Ohne nächste Ausführung';
  return 'Nächste Ausführung: ${dateTimeLabel(trigger.nextRunAt)}';
}

String dateTimeLabel(DateTime? value) {
  if (value == null) return '-';
  final date =
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
  return '$date, $time';
}

String weekdayLabels(List<int> weekdays) {
  return weekdays.map(_weekdayLabel).join(', ');
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mo',
    DateTime.tuesday => 'Di',
    DateTime.wednesday => 'Mi',
    DateTime.thursday => 'Do',
    DateTime.friday => 'Fr',
    DateTime.saturday => 'Sa',
    DateTime.sunday => 'So',
    _ => '?',
  };
}
