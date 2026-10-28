import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/widgets/adaptive_pickers.dart';
import '../../domain/entities/dialog_input_date_time_value.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import 'task_run_dialog_input_picker_field.dart';

/// Datumsfeld: öffnet den Kalender (Desktop) bzw. das Drehrad (Handy) und
/// sendet den Tag als `YYYY-MM-DD`.
class TaskRunDialogInputDate extends StatelessWidget {
  const TaskRunDialogInputDate({
    super.key,
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final String? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return TaskRunDialogInputPickerField(
      label: field.name,
      value: value,
      displayTextFor: (current) {
        final picked = DialogInputDateValue.tryParse(current);
        return picked == null ? null : _formatted(context, picked);
      },
      icon: Icons.calendar_today_outlined,
      pickLabel: LocaleKeys.ui_datum_auswaehlen.tr(),
      missingValueMessage: LocaleKeys.ui_bitte_ein_datum_waehlen.tr(),
      onPick: (current) =>
          _pick(context, DialogInputDateValue.tryParse(current)),
    );
  }

  String _formatted(BuildContext context, DialogInputDateValue date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMd(locale).format(date.toDateTime());
  }

  Future<String?> _pick(
    BuildContext context,
    DialogInputDateValue? date,
  ) async {
    final today = DateTime.now();
    final selected = await showAdaptiveDatePicker(
      context: context,
      initialDate: date?.toDateTime() ?? today,
      minimumDate: DateTime(1900),
      maximumDate: DateTime(today.year + 100, 12, 31),
    );
    if (selected == null) return null;
    final wire = DialogInputDateValue.of(selected).toWire();
    onValueChanged(field.name, wire);
    return wire;
  }
}

/// Uhrzeitfeld: öffnet die Uhrzeitauswahl und sendet sie als `HH:mm`.
class TaskRunDialogInputTime extends StatelessWidget {
  const TaskRunDialogInputTime({
    super.key,
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final String? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return TaskRunDialogInputPickerField(
      label: field.name,
      value: value,
      displayTextFor: (current) {
        final picked = DialogInputTimeValue.tryParse(current);
        return picked == null ? null : _formatted(context, picked);
      },
      icon: Icons.schedule_outlined,
      pickLabel: LocaleKeys.ui_uhrzeit_auswaehlen.tr(),
      missingValueMessage: LocaleKeys.ui_bitte_eine_uhrzeit_waehlen.tr(),
      onPick: (current) =>
          _pick(context, DialogInputTimeValue.tryParse(current)),
    );
  }

  String _formatted(BuildContext context, DialogInputTimeValue time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  Future<String?> _pick(
    BuildContext context,
    DialogInputTimeValue? time,
  ) async {
    final selected = await showAdaptiveTimePicker(
      context: context,
      initialTime: time == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: time.hour, minute: time.minute),
    );
    if (selected == null) return null;
    final wire = DialogInputTimeValue.of(
      hour: selected.hour,
      minute: selected.minute,
    ).toWire();
    onValueChanged(field.name, wire);
    return wire;
  }
}
