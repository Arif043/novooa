import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/runtime/webhooks_availability.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../cubits/event_target_options_cubit.dart';
import 'event_file_kind_chips.dart';
import 'event_target_field.dart';
import 'event_target_sheet.dart';
import 'schedule_choice_control.dart';
import 'webhook_controls.dart';

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
    required this.target,
    required this.fileKinds,
    required this.filterController,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onFileKindsChanged,
    required this.webhook,
    required this.onWebhookChanged,
  });

  final EventTriggerSource source;
  final EventTriggerTarget target;
  final Set<EventFileKind> fileKinds;
  final TextEditingController filterController;
  final ValueChanged<EventTriggerSource> onSourceChanged;
  final ValueChanged<EventTriggerTarget> onTargetChanged;
  final ValueChanged<Set<EventFileKind>> onFileKindsChanged;
  final WebhookConfig webhook;
  final ValueChanged<WebhookConfig> onWebhookChanged;

  bool get _isWebhook => source == EventTriggerSource.webhookReceived;

  bool get _hasTarget => source.targetScope != EventTargetScope.none;

  /// Dateikategorien sind nur sinnvoll, solange nicht eine einzelne Datei
  /// beobachtet wird — deren Typ steht ohnehin fest.
  bool get _showsFileKinds =>
      source.targetScope == EventTargetScope.files && target is! FileTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<EventTriggerSource>(
          isExpanded: true,
          initialValue: source,
          decoration: const InputDecoration(labelText: 'Ereignis'),
          items: [
            for (final item in EventTriggerSource.values)
              if (item != EventTriggerSource.webhookReceived ||
                  webhooksAvailable())
                _itemFor(item),
          ],
          onChanged: (value) {
            if (value != null) onSourceChanged(value);
          },
        ),
        if (_hasTarget) ...[
          const SizedBox(height: AppSpacing.md),
          EventTargetField(
            scope: source.targetScope,
            target: target,
            onTap: () => _pickTarget(context),
          ),
        ],
        if (_showsFileKinds) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Dateitypen', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          EventFileKindChips(
            selected: fileKinds,
            onChanged: onFileKindsChanged,
          ),
        ],
        if (_isWebhook) ...[
          const SizedBox(height: AppSpacing.md),
          WebhookControls(value: webhook, onChanged: onWebhookChanged),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          _MoreOptions(source: source, filterController: filterController),
        ],
      ],
    );
  }

  Future<void> _pickTarget(BuildContext context) async {
    final picked = await EventTargetSheet.show(
      context,
      source: source,
      initial: target,
      options: context.read<EventTargetOptionsCubit>(),
    );
    if (picked != null) onTargetChanged(picked);
  }

  DropdownMenuItem<EventTriggerSource> _itemFor(EventTriggerSource source) {
    return DropdownMenuItem(
      value: source,
      child: Text(source.label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _MoreOptions extends StatelessWidget {
  const _MoreOptions({required this.source, required this.filterController});

  final EventTriggerSource source;
  final TextEditingController filterController;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: const Text('Weitere Optionen'),
      initiallyExpanded: filterController.text.isNotEmpty,
      children: [
        TextField(
          controller: filterController,
          decoration: InputDecoration(
            labelText: 'Textfilter (optional)',
            helperText: _helper,
            helperMaxLines: 4,
          ),
        ),
      ],
    );
  }

  String get _helper {
    if (source.targetScope == EventTargetScope.files) {
      return 'Nur Dateien, deren Name diesen Text enthält.';
    }
    return 'Nur Ereignisse, deren Inhalt diesen Text enthält. '
        'Ohne Filter werden alle berücksichtigt.';
  }
}
