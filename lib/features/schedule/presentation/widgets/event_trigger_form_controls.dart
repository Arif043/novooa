import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';

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
    return SegmentedButton<TriggerFormMode>(
      segments: const [
        ButtonSegment(
          value: TriggerFormMode.schedule,
          icon: Icon(Icons.schedule_outlined),
          label: Text('Zeitplan'),
        ),
        ButtonSegment(
          value: TriggerFormMode.event,
          icon: Icon(Icons.bolt_outlined),
          label: Text('Ereignis'),
        ),
      ],
      selected: {value},
      onSelectionChanged: onChanged,
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
            labelText: 'Filter',
            hintText: 'z. B. Absender, Nummer, Pfad oder Topic',
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<EventTriggerSource> _itemFor(EventTriggerSource source) {
    return DropdownMenuItem(value: source, child: Text(source.label));
  }
}
