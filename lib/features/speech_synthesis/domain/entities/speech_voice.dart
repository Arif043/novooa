import 'package:equatable/equatable.dart';

class SpeechVoice extends Equatable {
  const SpeechVoice({
    required this.id,
    required this.name,
    this.description,
    this.language,
  });

  final String id;
  final String name;
  final String? description;
  final String? language;

  @override
  List<Object?> get props => [id, name, description, language];
}

/// Stimmen eines Sprachmodells samt der Stimme, die gilt, wenn keine gewählt ist.
class SpeechVoiceList extends Equatable {
  const SpeechVoiceList({
    required this.voices,
    required this.defaultVoiceId,
    required this.allowsCustomVoice,
  });

  final List<SpeechVoice> voices;
  final String defaultVoiceId;

  /// Der Anbieter nimmt auch Stimmen an, die nicht in der Liste stehen.
  final bool allowsCustomVoice;

  SpeechVoice? voiceById(String id) {
    for (final voice in voices) {
      if (voice.id == id) return voice;
    }
    return null;
  }

  @override
  List<Object?> get props => [voices, defaultVoiceId, allowsCustomVoice];
}
