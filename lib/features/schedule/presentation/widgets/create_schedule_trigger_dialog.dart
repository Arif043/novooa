import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/schedule_config.dart';
import '../cubits/schedule_cubit.dart';
import 'event_trigger_form_controls.dart';
import 'schedule_form_values.dart';
import 'schedule_trigger_form_controls.dart';
import 'time_trigger_controls.dart';

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
  TriggerFormMode _mode = TriggerFormMode.schedule;
  EventTriggerSource _eventSource = EventTriggerSource.emailReceived;
  final TextEditingController _eventFilterController = TextEditingController();
  ScheduleKind _kind = ScheduleKind.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _slotTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _slotWeekday = DateTime.monday;
  final ScheduleFormValues _values = const ScheduleFormValues();
  final List<WeeklyTimeSlot> _slots = [
    const WeeklyTimeSlot(weekday: DateTime.monday, timeOfDay: '09:00'),
  ];

  @override
  void initState() {
    super.initState();
    _task = widget.tasks.isEmpty ? null : widget.tasks.first;
  }

  @override
  void dispose() {
    _eventFilterController.dispose();
    super.dispose();
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
            TriggerModeSelector(value: _mode, onChanged: _setMode),
            const SizedBox(height: AppSpacing.md),
            if (_mode == TriggerFormMode.schedule) _scheduleControls(),
            if (_mode == TriggerFormMode.event) _eventControls(),
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
        (_mode == TriggerFormMode.event ||
            _kind != ScheduleKind.weekly ||
            _slots.isNotEmpty);
  }

  void _setTask(Task? task) => setState(() => _task = task);

  void _setMode(Set<TriggerFormMode> value) {
    setState(() => _mode = value.first);
  }

  void _setKind(Set<ScheduleKind> value) => setState(() => _kind = value.first);

  Widget _scheduleControls() {
    return TimeTriggerControls(
      kind: _kind,
      date: _date,
      time: _time,
      slotTime: _slotTime,
      slotWeekday: _slotWeekday,
      slots: _slots,
      onKindChanged: _setKind,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onSlotWeekdayChanged: _setSlotWeekday,
      onPickSlotTime: _pickSlotTime,
      onAddSlot: _addSlot,
      onRemoveSlot: _removeSlot,
    );
  }

  Widget _eventControls() {
    return EventTriggerControls(
      source: _eventSource,
      filterController: _eventFilterController,
      onSourceChanged: (source) => setState(() => _eventSource = source),
    );
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
      timeOfDay: _values.timeLabel(_slotTime),
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
    if (_mode == TriggerFormMode.schedule) {
      await widget.cubit.createTrigger(task, _config());
    } else {
      await widget.cubit.createEventTrigger(task, _eventConfig());
    }
    if (mounted) Navigator.of(context).pop();
  }

  EventTriggerConfig _eventConfig() => EventTriggerConfig(
    source: _eventSource,
    filter: _eventFilterController.text.trim(),
  );

  ScheduleConfig _config() =>
      _values.config(kind: _kind, date: _date, time: _time, slots: _slots);
}
