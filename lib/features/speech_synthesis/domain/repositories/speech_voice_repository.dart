import '../entities/speech_voice.dart';

abstract interface class SpeechVoiceRepository {
  /// Fragt die Stimmen beim Anbieter des Sprachmodells ab. Wirft eine
  /// [SpeechVoicesException] mit lesbarer Meldung, wenn der Anbieter ablehnt.
  Future<SpeechVoiceList> listVoices(String languageModelId);
}

class SpeechVoicesException implements Exception {
  const SpeechVoicesException(this.message);

  final String message;

  @override
  String toString() => message;
}
