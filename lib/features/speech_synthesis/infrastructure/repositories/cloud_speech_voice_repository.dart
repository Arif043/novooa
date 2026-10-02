import 'package:cloud_functions/cloud_functions.dart';
import 'package:syscat2/core/firebase/firebase_region.dart';

import '../../domain/entities/speech_voice.dart';
import '../../domain/repositories/speech_voice_repository.dart';
import 'speech_voice_list_mapper.dart';

class CloudSpeechVoiceRepository implements SpeechVoiceRepository {
  CloudSpeechVoiceRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final FirebaseFunctions _functions;

  @override
  Future<SpeechVoiceList> listVoices(String languageModelId) async {
    try {
      final result = await _functions.httpsCallable('listSpeechVoices').call({
        'languageModelId': languageModelId,
      });
      return speechVoiceListFromJson(result.data as Map<Object?, Object?>);
    } on FirebaseFunctionsException catch (error) {
      throw SpeechVoicesException(
        error.message ?? 'Stimmen konnten nicht geladen werden.',
      );
    }
  }
}
