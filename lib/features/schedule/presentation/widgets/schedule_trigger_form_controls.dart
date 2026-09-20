import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/schedule_config.dart';
import 'schedule_choice_control.dart';

class ScheduleTaskDropdown extends StatelessWidget {
  const ScheduleTaskDropdown({
    super.key,
    required this.tasks,
    required this.value,
    required this.onChanged,
  });

  final List<Task> tasks;
  final Task? value;
  final ValueChanged<Task?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Task>(
      isExpanded: true,
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Aufgabe'),
      items: tasks.map(_itemFor).toList(growable: false),
      onChanged: tasks.isEmpty ? null : onChanged,
    );
  }

  DropdownMenuItem<Task> _itemFor(Task task) {
    return DropdownMenuItem(
      value: task,
      child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class ScheduleKindSelector extends StatelessWidget {
  const ScheduleKindSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ScheduleKind value;
  final ValueChanged<Set<ScheduleKind>> onChanged;

  @override
  Widget build(BuildContext context) {
    return ScheduleChoiceControl<ScheduleKind>(
      value: value,
      label: 'Wiederholung',
      labels: const {
        ScheduleKind.once: 'Einmalig',
        ScheduleKind.daily: 'Täglich',
        ScheduleKind.weekly: 'Wöchentlich',
      },
      onChanged: (value) => onChanged({value}),
    );
  }
}

class ScheduleDateButton extends StatelessWidget {
  const ScheduleDateButton({
    super.key,
    required this.date,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPick,
      icon: const Icon(CupertinoIcons.calendar),
      label: Text('Datum · $_dateLabel'),
    );
  }

  String get _dateLabel {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class ScheduleTimeButton extends StatelessWidget {
  const ScheduleTimeButton({
    super.key,
    required this.time,
    required this.onPick,
  });

  final TimeOfDay time;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPick,
      icon: const Icon(CupertinoIcons.clock),
      label: Text('Uhrzeit · $_timeLabel'),
    );
  }

  String get _timeLabel {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: _weekdays.map(_chipFor).toList(growable: false),
    );
  }

  Widget _chipFor(({int value, String label}) weekday) {
    return FilterChip(
      label: Text(weekday.label),
      selected: selected.contains(weekday.value),
      onSelected: (_) => onToggle(weekday.value),
    );
  }
}

const _weekdays = [
  (value: DateTime.monday, label: 'Mo'),
  (value: DateTime.tuesday, label: 'Di'),
  (value: DateTime.wednesday, label: 'Mi'),
  (value: DateTime.thursday, label: 'Do'),
  (value: DateTime.friday, label: 'Fr'),
  (value: DateTime.saturday, label: 'Sa'),
  (value: DateTime.sunday, label: 'So'),
];
