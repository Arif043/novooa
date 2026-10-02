import '../../domain/entities/speech_voice.dart';

/// Wire-Format von lokaler Runtime und Cloud-Funktion `listSpeechVoices`.
SpeechVoiceList speechVoiceListFromJson(Map<Object?, Object?> json) {
  final voices = json['voices'];
  final defaultVoiceId = json['defaultVoiceId'];
  if (voices is! List || defaultVoiceId is! String) {
    throw const FormatException('Die Stimmenliste ist ungültig.');
  }
  return SpeechVoiceList(
    voices: voices.map(_voiceFrom).toList(growable: false),
    defaultVoiceId: defaultVoiceId,
    allowsCustomVoice: json['allowsCustomVoice'] == true,
  );
}

SpeechVoice _voiceFrom(Object? value) {
  if (value is! Map || value['id'] is! String || value['name'] is! String) {
    throw const FormatException('Eine Stimme ist ungültig.');
  }
  return SpeechVoice(
    id: value['id'] as String,
    name: value['name'] as String,
    description: value['description'] as String?,
    language: value['language'] as String?,
  );
}
