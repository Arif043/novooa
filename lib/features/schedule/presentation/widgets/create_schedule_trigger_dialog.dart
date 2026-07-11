import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/schedule_config.dart';
import '../cubits/schedule_cubit.dart';
import 'schedule_trigger_form_controls.dart';
import 'weekly_time_slot_selector.dart';

class CreateScheduleTriggerDialog extends StatefulWidget {
  const CreateScheduleTriggerDialog({
    super.key,
    required this.tasks,
    required this.cubit,
  });

  final List<Task> tasks;
  final ScheduleCubit cubit;

  @override
  State<CreateScheduleTriggerDialog> createState() =>
      _CreateScheduleTriggerDialogState();
}

class _CreateScheduleTriggerDialogState
    extends State<CreateScheduleTriggerDialog> {
  Task? _task;
  ScheduleKind _kind = ScheduleKind.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _slotTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _slotWeekday = DateTime.monday;
  final List<WeeklyTimeSlot> _slots = [
    const WeeklyTimeSlot(weekday: DateTime.monday, timeOfDay: '09:00'),
  ];

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
              WeeklyTimeSlotSelector(
                slots: _slots,
                weekday: _slotWeekday,
                time: _slotTime,
                onWeekdayChanged: _setSlotWeekday,
                onPickTime: _pickSlotTime,
                onAdd: _addSlot,
                onRemove: _removeSlot,
              ),
            const SizedBox(height: AppSpacing.md),
            if (_kind != ScheduleKind.weekly)
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
    return _task != null && (_kind != ScheduleKind.weekly || _slots.isNotEmpty);
  }

  void _setTask(Task? task) => setState(() => _task = task);

  void _setKind(Set<ScheduleKind> value) => setState(() => _kind = value.first);

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

  void _setSlotWeekday(int weekday) => setState(() => _slotWeekday = weekday);

  Future<void> _pickSlotTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _slotTime,
    );
    if (selected == null) return;
    setState(() => _slotTime = selected);
  }

  void _addSlot() {
    final slot = WeeklyTimeSlot(
      weekday: _slotWeekday,
      timeOfDay: _slotTimeLabel,
    );
    if (_slots.any(_sameSlot(slot))) return;
    setState(() => _slots.add(slot));
  }

  void _removeSlot(WeeklyTimeSlot slot) {
    setState(() {
      _slots.removeWhere(_sameSlot(slot));
    });
  }

  bool Function(WeeklyTimeSlot item) _sameSlot(WeeklyTimeSlot slot) {
    return (item) {
      return item.weekday == slot.weekday && item.timeOfDay == slot.timeOfDay;
    };
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
        runAt: _runAt,
      ),
      ScheduleKind.daily => ScheduleConfig(
        kind: _kind,
        timezone: 'Europe/Berlin',
        timeOfDay: _timeLabel,
      ),
      ScheduleKind.weekly => ScheduleConfig(
        kind: _kind,
        timezone: 'Europe/Berlin',
        slots: _slots,
      ),
    };
  }

  String get _timeLabel {
    return '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}';
  }

  DateTime get _runAt {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  String get _slotTimeLabel {
    return '${_slotTime.hour.toString().padLeft(2, '0')}:'
        '${_slotTime.minute.toString().padLeft(2, '0')}';
  }
}
