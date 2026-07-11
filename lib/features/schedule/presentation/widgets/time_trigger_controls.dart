import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/schedule_config.dart';
import 'schedule_trigger_form_controls.dart';
import 'weekly_time_slot_selector.dart';

class TimeTriggerControls extends StatelessWidget {
  const TimeTriggerControls({
    super.key,
    required this.kind,
    required this.date,
    required this.time,
    required this.slotTime,
    required this.slotWeekday,
    required this.slots,
    required this.onKindChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSlotWeekdayChanged,
    required this.onPickSlotTime,
    required this.onAddSlot,
    required this.onRemoveSlot,
  });

  final ScheduleKind kind;
  final DateTime date;
  final TimeOfDay time;
  final TimeOfDay slotTime;
  final int slotWeekday;
  final List<WeeklyTimeSlot> slots;
  final ValueChanged<Set<ScheduleKind>> onKindChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<int> onSlotWeekdayChanged;
  final VoidCallback onPickSlotTime;
  final VoidCallback onAddSlot;
  final ValueChanged<WeeklyTimeSlot> onRemoveSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScheduleKindSelector(value: kind, onChanged: onKindChanged),
        const SizedBox(height: AppSpacing.md),
        if (kind == ScheduleKind.once)
          ScheduleDateButton(date: date, onPick: onPickDate),
        if (kind == ScheduleKind.weekly)
          WeeklyTimeSlotSelector(
            slots: slots,
            weekday: slotWeekday,
            time: slotTime,
            onWeekdayChanged: onSlotWeekdayChanged,
            onPickTime: onPickSlotTime,
            onAdd: onAddSlot,
            onRemove: onRemoveSlot,
          ),
        const SizedBox(height: AppSpacing.md),
        if (kind != ScheduleKind.weekly)
          ScheduleTimeButton(time: time, onPick: onPickTime),
      ],
    );
  }
}
