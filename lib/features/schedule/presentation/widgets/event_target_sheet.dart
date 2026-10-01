import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../cubits/event_target_options_cubit.dart';
import '../cubits/event_target_options_state.dart';
import 'event_channel_target_picker.dart';
import 'event_file_target_picker.dart';
import 'event_target_labels.dart';

/// Auswahl-Sheet für das Ziel eines Event-Triggers. Liefert das gewählte Ziel
/// beim „Übernehmen" zurück, bei Abbruch `null`.
class EventTargetSheet extends StatefulWidget {
  const EventTargetSheet({
    super.key,
    required this.source,
    required this.initial,
  });

  final EventTriggerSource source;
  final EventTriggerTarget initial;

  static Future<EventTriggerTarget?> show(
    BuildContext context, {
    required EventTriggerSource source,
    required EventTriggerTarget initial,
    required EventTargetOptionsCubit options,
  }) {
    return showModalBottomSheet<EventTriggerTarget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => BlocProvider.value(
        value: options,
        child: EventTargetSheet(source: source, initial: initial),
      ),
    );
  }

  @override
  State<EventTargetSheet> createState() => _EventTargetSheetState();
}

class _EventTargetSheetState extends State<EventTargetSheet> {
  late EventTriggerTarget _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              eventTargetFieldLabel(widget.source.targetScope),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child:
                  BlocBuilder<EventTargetOptionsCubit, EventTargetOptionsState>(
                    builder: (context, options) => _body(context, options),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, EventTargetOptionsState options) {
    return switch (options.status) {
      EventTargetOptionsStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      EventTargetOptionsStatus.failure => _LoadError(
        onRetry: context.read<EventTargetOptionsCubit>().load,
      ),
      EventTargetOptionsStatus.ready => _picker(options),
    };
  }

  Widget _picker(EventTargetOptionsState options) {
    if (widget.source.targetScope == EventTargetScope.files) {
      return EventFileTargetPicker(
        options: options,
        selected: _selected,
        onChanged: _select,
      );
    }
    return EventChannelTargetPicker(
      source: widget.source,
      options: options,
      selected: _selected,
      onChanged: _select,
    );
  }

  void _select(EventTriggerTarget target) => setState(() => _selected = target);
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Die Auswahl konnte nicht geladen werden.'),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
        ],
      ),
    );
  }
}
