import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';

import '../../domain/repositories/speech_voice_repository.dart';
import '../../domain/usecases/list_speech_voices.dart';
import 'speech_voices_state.dart';

/// Lädt die Stimmen des gewählten Sprachmodells; ein Cubit je Modell.
class SpeechVoicesCubit extends Cubit<SpeechVoicesState> {
  SpeechVoicesCubit(this._listSpeechVoices, this.languageModelId)
    : super(const SpeechVoicesState());

  final ListSpeechVoices _listSpeechVoices;
  final String languageModelId;

  Future<void> load() async {
    emit(const SpeechVoicesState());
    try {
      final voices = await _listSpeechVoices(languageModelId);
      if (!isClosed) {
        emit(
          SpeechVoicesState(status: SpeechVoicesStatus.ready, voices: voices),
        );
      }
    } on SpeechVoicesException catch (error) {
      _emitFailure(error.message);
    } catch (error, stackTrace) {
      logException(
        message: 'Stimmen konnten nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'speech_voices',
      );
      _emitFailure('Stimmen konnten nicht geladen werden.');
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      SpeechVoicesState(status: SpeechVoicesStatus.failure, message: message),
    );
  }
}
