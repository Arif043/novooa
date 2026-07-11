import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/schedule_config.dart';
import 'schedule_formatters.dart';

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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _WeekdayDropdown(value: weekday, onChanged: onWeekdayChanged),
            OutlinedButton.icon(
              onPressed: onPickTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_timeLabel),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Zeit hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (slots.isEmpty)
          Text(
            'Noch kein Zeitpunkt ausgewählt.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: slots.map(_chipFor).toList(growable: false),
          ),
      ],
    );
  }

  Widget _chipFor(WeeklyTimeSlot slot) {
    return InputChip(
      label: Text(slotLabels([slot])),
      onDeleted: () => onRemove(slot),
    );
  }

  String get _timeLabel {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _WeekdayDropdown extends StatelessWidget {
  const _WeekdayDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
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
