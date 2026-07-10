import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/schedule_config.dart';
import '../cubits/schedule_cubit.dart';
import 'schedule_trigger_form_controls.dart';

class CreateScheduleTriggerDialog extends StatefulWidget {
  const CreateScheduleTriggerDialog({
    super.key,
    required this.tasks,
    required this.cubit,
  });

  final List<Task> tasks;
  final ScheduleCubit cubit;

  static Future<void> show(
    BuildContext context, {
    required List<Task> tasks,
    required ScheduleCubit cubit,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CreateScheduleTriggerDialog(tasks: tasks, cubit: cubit),
    );
  }

  @override
  State<CreateScheduleTriggerDialog> createState() {
    return _CreateScheduleTriggerDialogState();
  }
}

class _CreateScheduleTriggerDialogState
    extends State<CreateScheduleTriggerDialog> {
  Task? _task;
  ScheduleKind _kind = ScheduleKind.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final Set<int> _weekdays = {DateTime.monday};

  @override
  void initState() {
    super.initState();
    _task = widget.tasks.isEmpty ? null : widget.tasks.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trigger hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScheduleTaskDropdown(
              tasks: widget.tasks,
              value: _task,
              onChanged: _setTask,
            ),
            const SizedBox(height: AppSpacing.md),
            ScheduleKindSelector(value: _kind, onChanged: _setKind),
            const SizedBox(height: AppSpacing.md),
            if (_kind == ScheduleKind.once)
              ScheduleDateButton(date: _date, onPick: _pickDate),
            if (_kind == ScheduleKind.weekly)
              WeekdaySelector(selected: _weekdays, onToggle: _toggleWeekday),
            const SizedBox(height: AppSpacing.md),
            ScheduleTimeButton(time: _time, onPick: _pickTime),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    return _task != null &&
        (_kind != ScheduleKind.weekly || _weekdays.isNotEmpty);
  }

  void _setTask(Task? task) => setState(() => _task = task);

  void _setKind(Set<ScheduleKind> value) {
    setState(() => _kind = value.first);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected == null) return;
    setState(() => _time = selected);
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      _weekdays.contains(weekday)
          ? _weekdays.remove(weekday)
          : _weekdays.add(weekday);
    });
  }

  Future<void> _submit() async {
    final task = _task;
    if (task == null) return;
    await widget.cubit.createTrigger(task, _config());
    if (mounted) Navigator.of(context).pop();
  }

  ScheduleConfig _config() {
    return switch (_kind) {
      ScheduleKind.once => ScheduleConfig(
        kind: _kind,
        timezone: 'Europe/Berlin',
        runAt: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
      ),
      ScheduleKind.daily => ScheduleConfig(
        kind: _kind,
        timezone: 'Europe/Berlin',
        timeOfDay: _timeLabel,
      ),
      ScheduleKind.weekly => ScheduleConfig(
        kind: _kind,
        timezone: 'Europe/Berlin',
        timeOfDay: _timeLabel,
        weekdays: _weekdays.toList()..sort(),
      ),
    };
  }

  String get _timeLabel {
    return '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}';
  }
}
