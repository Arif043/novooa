import '../entities/speech_voice.dart';
import '../repositories/speech_voice_repository.dart';

class ListSpeechVoices {
  const ListSpeechVoices(this._repository);

  final SpeechVoiceRepository _repository;

  Future<SpeechVoiceList> call(String languageModelId) {
    return _repository.listVoices(languageModelId);
  }
}
