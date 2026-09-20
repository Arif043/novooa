import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';
import 'schedule_choice_control.dart';

enum TriggerFormMode { schedule, event }

class TriggerModeSelector extends StatelessWidget {
  const TriggerModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TriggerFormMode value;
  final ValueChanged<Set<TriggerFormMode>> onChanged;

  @override
  Widget build(BuildContext context) {
    return ScheduleChoiceControl<TriggerFormMode>(
      value: value,
      label: 'Auslöser',
      labels: const {
        TriggerFormMode.schedule: 'Zeitplan',
        TriggerFormMode.event: 'Ereignis',
      },
      onChanged: (value) => onChanged({value}),
    );
  }
}

class EventTriggerControls extends StatelessWidget {
  const EventTriggerControls({
    super.key,
    required this.source,
    required this.filterController,
    required this.onSourceChanged,
  });

  final EventTriggerSource source;
  final TextEditingController filterController;
  final ValueChanged<EventTriggerSource> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<EventTriggerSource>(
          isExpanded: true,
          initialValue: source,
          decoration: const InputDecoration(labelText: 'Ereignis'),
          items: EventTriggerSource.values.map(_itemFor).toList(),
          onChanged: (value) {
            if (value != null) onSourceChanged(value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: filterController,
          decoration: const InputDecoration(
            labelText: 'Filter (optional)',
            helperText:
                'Ohne Filter werden alle passenden Ereignisse berücksichtigt.',
            helperMaxLines: 4,
            hintText: 'z. B. Absender, Nummer, Pfad oder Topic',
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<EventTriggerSource> _itemFor(EventTriggerSource source) {
    return DropdownMenuItem(
      value: source,
      child: Text(source.label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
