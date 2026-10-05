import '../../domain/entities/event_trigger_config.dart';
import 'event_target_labels.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';

String triggerLabel(TaskTrigger trigger) {
  return switch (trigger.type) {
    TriggerType.schedule => scheduleLabel(trigger.schedule),
    TriggerType.event => eventLabel(trigger.event),
  };
}

String scheduleLabel(ScheduleConfig? config) {
  if (config == null) return 'Zeitplan nicht konfiguriert';
  return switch (config.kind) {
    ScheduleKind.once => 'Einmalig am ${dateTimeLabel(config.runAt)}',
    ScheduleKind.daily => 'Täglich um ${config.timeOfDay}',
    ScheduleKind.weekly => 'Wöchentlich ${slotLabels(config.slots)}',
  };
}

String eventLabel(EventTriggerConfig? config) {
  if (config == null) return 'Ereignis nicht konfiguriert';
  final parts = [
    if (config.source == EventTriggerSource.shopware)
      'Shopware: ${config.shopware.summary}'
    else
      config.source.label,
    if (config.target is! AnywhereTarget) eventTargetLabel(config.target),
    if (config.fileKinds.isNotEmpty && config.target is! FileTarget)
      config.fileKinds.map((kind) => kind.label).join(', '),
    if (config.filter.trim().isNotEmpty) '„${config.filter.trim()}“',
  ];
  return parts.join(' · ');
}

String triggerStatusLabel(TaskTrigger trigger) {
  if (!trigger.enabled) return 'Pausiert';
  if (trigger.type == TriggerType.event) return 'Wartet auf Ereignis';
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

String slotLabels(List<WeeklyTimeSlot> slots) {
  return slots
      .map((slot) => '${_weekdayLabel(slot.weekday)} ${slot.timeOfDay}')
      .join(', ');
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
