import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../../task_builder/domain/entities/task.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/schedule_config.dart';
import '../cubits/event_target_options_cubit.dart';
import '../cubits/schedule_cubit.dart';
import 'event_trigger_form_controls.dart';
import 'schedule_form_values.dart';
import 'schedule_trigger_form_controls.dart';
import 'time_trigger_controls.dart';
import 'trigger_cycle_warning_dialog.dart';
import 'schedule_theme.dart';

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
  bool _saving = false;
  String? _error;
  TriggerFormMode _mode = TriggerFormMode.schedule;
  EventTriggerSource _eventSource = EventTriggerSource.emailReceived;
  EventTriggerTarget _eventTarget = EventTriggerTarget.anywhere;
  Set<EventFileKind> _eventFileKinds = const {};
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
    return BlocProvider(
      // Lazy: Die Optionen werden erst geladen, wenn die Zielwahl geöffnet wird.
      create: (_) => serviceLocator<EventTargetOptionsCubit>()..load(),
      child: Theme(
        data: ScheduleTheme.from(Theme.of(context)),
        child: Builder(
          builder: (context) => PopScope(
            canPop: !_saving,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Auslöser hinzufügen',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Schließen',
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(CupertinoIcons.xmark, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lege fest, wann deine Aufgabe automatisch startet.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ScheduleSection(
                        title: 'Aufgabe',
                        child: ScheduleTaskDropdown(
                          tasks: widget.tasks,
                          value: _task,
                          onChanged: _setTask,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TriggerModeSelector(value: _mode, onChanged: _setMode),
                      const SizedBox(height: AppSpacing.lg),
                      ScheduleSection(
                        title: _mode == TriggerFormMode.schedule
                            ? 'Wann soll die Aufgabe starten?'
                            : 'Was soll die Aufgabe auslösen?',
                        child: _mode == TriggerFormMode.schedule
                            ? _scheduleControls()
                            : _eventControls(),
                      ),
                      if (_mode == TriggerFormMode.schedule) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Zeitzone: Europe/Berlin',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _canSubmit && !_saving ? _submit : null,
                        child: _saving
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CupertinoActivityIndicator(),
                              )
                            : const Text('Auslöser erstellen'),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Abbrechen'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
      target: _eventTarget,
      fileKinds: _eventFileKinds,
      filterController: _eventFilterController,
      onSourceChanged: _setEventSource,
      onTargetChanged: (target) => setState(() => _eventTarget = target),
      onFileKindsChanged: (kinds) => setState(() => _eventFileKinds = kinds),
    );
  }

  /// Ein Ziel gilt nur für die Art von Ereignis, für die es gewählt wurde.
  void _setEventSource(EventTriggerSource source) {
    final sameScope = source.targetScope == _eventSource.targetScope;
    setState(() {
      if (!sameScope || source.targetScope == EventTargetScope.channel) {
        _eventTarget = EventTriggerTarget.anywhere;
      }
      if (source.targetScope != EventTargetScope.files) {
        _eventFileKinds = const {};
      }
      _eventSource = source;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showIosDatePicker(
      context: context,
      initialDate: _date,
      minimumDate: DateTime.now(),
      maximumDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showIosTimePicker(
      context: context,
      initialTime: _time,
    );
    if (selected == null) return;
    setState(() => _time = selected);
  }

  void _setSlotWeekday(int weekday) => setState(() => _slotWeekday = weekday);

  Future<void> _pickSlotTime() async {
    final selected = await showIosTimePicker(
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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_mode == TriggerFormMode.schedule) {
        await widget.cubit.createTrigger(task, _config());
      } else if (!await _createEventTrigger(task)) {
        return;
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Der Auslöser konnte nicht erstellt werden. Deine Eingaben bleiben erhalten. Bitte versuche es erneut.';
        });
      }
    }
  }

  /// Prüft vorab auf Schleifen: Eine Selbstschleife stoppt hier, mögliche
  /// Schleifen muss der Nutzer bestätigen. Liefert `false`, wenn nicht
  /// erstellt wurde.
  Future<bool> _createEventTrigger(Task task) async {
    final event = _eventConfig();
    final analysis = await widget.cubit.analyzeEventTrigger(task, event);
    if (!mounted) return false;
    if (analysis.isBlocked) return _stop(analysis.blocked);
    if (analysis.hasWarnings && !await _confirmWarnings(analysis.warnings)) {
      return _stop(null);
    }
    await widget.cubit.createEventTrigger(task, event);
    return true;
  }

  /// Während der Rückfrage läuft nichts im Hintergrund: Der Dialog zeigt keinen
  /// Ladezustand und der Button bleibt bedienbar.
  Future<bool> _confirmWarnings(List<String> warnings) async {
    setState(() => _saving = false);
    final confirmed = await TriggerCycleWarningDialog.show(context, warnings);
    if (confirmed && mounted) setState(() => _saving = true);
    return confirmed;
  }

  bool _stop(String? message) {
    if (mounted) {
      setState(() {
        _saving = false;
        _error = message;
      });
    }
    return false;
  }

  EventTriggerConfig _eventConfig() => EventTriggerConfig(
    source: _eventSource,
    target: _eventTarget,
    fileKinds: _eventFileKinds,
    filter: _eventFilterController.text.trim(),
  );

  ScheduleConfig _config() =>
      _values.config(kind: _kind, date: _date, time: _time, slots: _slots);
}
