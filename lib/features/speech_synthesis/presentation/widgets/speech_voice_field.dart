import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/speech_voice.dart';
import '../cubits/speech_voices_cubit.dart';
import '../cubits/speech_voices_state.dart';
import 'speech_voice_sheet.dart';

/// Feld „Stimme": zeigt die Wahl und öffnet die Stimmenliste des Anbieters.
/// Ohne Wahl gilt die Standardstimme, eine Auswahl ist also nie Pflicht.
/// Erwartet einen [SpeechVoicesCubit] im Baum.
class SpeechVoiceField extends StatelessWidget {
  const SpeechVoiceField({
    super.key,
    required this.selectedVoiceId,
    required this.onChanged,
  });

  final String selectedVoiceId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechVoicesCubit, SpeechVoicesState>(
      builder: (context, state) => switch (state.status) {
        SpeechVoicesStatus.loading => const _VoiceStatusRow(
          icon: SizedBox.square(
            dimension: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          text: 'Stimmen werden geladen …',
        ),
        SpeechVoicesStatus.failure => _VoiceStatusRow(
          icon: const Icon(Icons.error_outline),
          text: state.message ?? 'Stimmen konnten nicht geladen werden.',
          onRetry: context.read<SpeechVoicesCubit>().load,
        ),
        SpeechVoicesStatus.ready => _ReadyField(
          voices: state.voices!,
          selectedVoiceId: selectedVoiceId,
          onChanged: onChanged,
        ),
      },
    );
  }
}

class _ReadyField extends StatelessWidget {
  const _ReadyField({
    required this.voices,
    required this.selectedVoiceId,
    required this.onChanged,
  });

  final SpeechVoiceList voices;
  final String selectedVoiceId;
  final ValueChanged<String> onChanged;

  String get _label {
    if (selectedVoiceId.isEmpty) {
      final voice = voices.voiceById(voices.defaultVoiceId);
      return voice == null
          ? 'Standardstimme'
          : 'Standardstimme (${voice.name})';
    }
    return voices.voiceById(selectedVoiceId)?.name ?? selectedVoiceId;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Stimme: $_label. Auswahl öffnen',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: () => _open(context),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Stimme'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.unfold_more),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await SpeechVoiceSheet.show(
      context,
      voices: voices,
      selectedVoiceId: selectedVoiceId,
    );
    if (picked != null) onChanged(picked);
  }
}

class _VoiceStatusRow extends StatelessWidget {
  const _VoiceStatusRow({required this.icon, required this.text, this.onRetry});

  final Widget icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Stimme'),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
        ],
      ),
    );
  }
}
