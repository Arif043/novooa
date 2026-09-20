import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/schedule_config.dart';
import 'schedule_formatters.dart';
import 'schedule_trigger_form_controls.dart';

class WeeklyTimeSlotSelector extends StatelessWidget {
  const WeeklyTimeSlotSelector({
    super.key,
    required this.slots,
    required this.weekday,
    required this.time,
    required this.onWeekdayChanged,
    required this.onPickTime,
    required this.onAdd,
    required this.onRemove,
  });

  final List<WeeklyTimeSlot> slots;
  final int weekday;
  final TimeOfDay time;
  final ValueChanged<int> onWeekdayChanged;
  final VoidCallback onPickTime;
  final VoidCallback onAdd;
  final ValueChanged<WeeklyTimeSlot> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekdayDropdown(value: weekday, onChanged: onWeekdayChanged),
        const SizedBox(height: AppSpacing.sm),
        ScheduleTimeButton(time: time, onPick: onPickTime),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(CupertinoIcons.add),
          label: const Text('Zeit hinzufügen'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (slots.isEmpty)
          Text(
            'Noch kein Zeitpunkt ausgewählt.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...slots.map(
            (slot) => Row(
              children: [
                Expanded(
                  child: Text(
                    slotLabels([slot]),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  tooltip: '${slotLabels([slot])} entfernen',
                  onPressed: () => onRemove(slot),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(CupertinoIcons.minus_circle),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekdayDropdown extends StatelessWidget {
  const _WeekdayDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Wochentag'),
      items: _weekdays.map(_itemFor).toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  DropdownMenuItem<int> _itemFor(({int value, String label}) weekday) {
    return DropdownMenuItem(value: weekday.value, child: Text(weekday.label));
  }
}

const _weekdays = [
  (value: DateTime.monday, label: 'Montag'),
  (value: DateTime.tuesday, label: 'Dienstag'),
  (value: DateTime.wednesday, label: 'Mittwoch'),
  (value: DateTime.thursday, label: 'Donnerstag'),
  (value: DateTime.friday, label: 'Freitag'),
  (value: DateTime.saturday, label: 'Samstag'),
  (value: DateTime.sunday, label: 'Sonntag'),
];
