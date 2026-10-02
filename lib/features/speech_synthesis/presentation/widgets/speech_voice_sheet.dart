import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

import '../../domain/entities/speech_voice.dart';

/// Ergebnis der Auswahl: `''` steht für die Standardstimme des Anbieters.
const defaultSpeechVoiceId = '';

/// Auswahl einer Stimme mit Suche. Liefert die Stimmen-ID, [defaultSpeechVoiceId]
/// für die Standardstimme oder `null`, wenn das Sheet ohne Auswahl schließt.
class SpeechVoiceSheet {
  const SpeechVoiceSheet._();

  static Future<String?> show(
    BuildContext context, {
    required SpeechVoiceList voices,
    required String selectedVoiceId,
  }) {
    return showAdaptiveSheet<String>(
      context: context,
      builder: (_, style) => _SpeechVoiceContent(
        style: style,
        voices: voices,
        selectedVoiceId: selectedVoiceId,
      ),
    );
  }
}

class _SpeechVoiceContent extends StatefulWidget {
  const _SpeechVoiceContent({
    required this.style,
    required this.voices,
    required this.selectedVoiceId,
  });

  final AdaptiveSheetStyle style;
  final SpeechVoiceList voices;
  final String selectedVoiceId;

  @override
  State<_SpeechVoiceContent> createState() => _SpeechVoiceContentState();
}

class _SpeechVoiceContentState extends State<_SpeechVoiceContent> {
  static const _windowSheetHeight = 520.0;
  String _query = '';

  List<SpeechVoice> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.voices.voices;
    return widget.voices.voices
        .where((voice) => _searchable(voice).contains(query))
        .toList(growable: false);
  }

  /// Dienste wie OpenAI-kompatible Server kennen Stimmen, die keine Liste
  /// nennt; der Suchtext lässt sich dann als Stimmen-ID übernehmen.
  bool get _offersCustomVoice {
    final query = _query.trim();
    return widget.voices.allowsCustomVoice &&
        query.isNotEmpty &&
        widget.voices.voiceById(query) == null;
  }

  String _searchable(SpeechVoice voice) =>
      '${voice.name} ${voice.description ?? ''} ${voice.language ?? ''}'
          .toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isWindow = widget.style.isWindow;
    final matches = _matches;
    final defaultVoice = widget.voices.voiceById(widget.voices.defaultVoiceId);
    return SizedBox(
      height: isWindow
          ? _windowSheetHeight
          : MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Stimme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Stimme suchen',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text(
                    defaultVoice == null
                        ? 'Standardstimme'
                        : 'Standardstimme (${defaultVoice.name})',
                  ),
                  selected: widget.selectedVoiceId == defaultSpeechVoiceId,
                  onTap: () => Navigator.of(context).pop(defaultSpeechVoiceId),
                ),
                for (final voice in matches) _voiceTile(context, voice),
                if (_offersCustomVoice)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text('Eigene Stimme „${_query.trim()}“ verwenden'),
                    onTap: () => Navigator.of(context).pop(_query.trim()),
                  )
                else if (matches.isEmpty)
                  const _NoMatches(),
              ],
            ),
          ),
          if (isWindow) ...[
            const Divider(height: 1),
            SheetFooter(onCancel: () => Navigator.of(context).pop()),
          ],
        ],
      ),
    );
  }

  Widget _voiceTile(BuildContext context, SpeechVoice voice) {
    final details = [
      if (voice.description != null) voice.description!,
      if (voice.language != null) voice.language!,
    ].join(' · ');
    return ListTile(
      title: Text(voice.name),
      subtitle: details.isEmpty ? null : Text(details),
      selected: voice.id == widget.selectedVoiceId,
      trailing: voice.id == widget.selectedVoiceId
          ? const Icon(Icons.check)
          : null,
      onTap: () => Navigator.of(context).pop(voice.id),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Text('Keine Stimme gefunden.'),
    );
  }
}
