import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/speech_voice.dart';
import '../../domain/repositories/speech_voice_repository.dart';
import 'speech_voice_list_mapper.dart';

class LocalSpeechVoiceRepository implements SpeechVoiceRepository {
  const LocalSpeechVoiceRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<SpeechVoiceList> listVoices(String languageModelId) async {
    try {
      final response = await _client.get(
        '/v1/language-models/${Uri.encodeComponent(languageModelId)}/voices',
      );
      return speechVoiceListFromJson(response);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw SpeechVoicesException(_messageFrom(error));
    }
  }

  String _messageFrom(Object error) {
    if (error is WorkspaceHttpException && error.message.isNotEmpty) {
      return error.message;
    }
    return 'Stimmen konnten nicht geladen werden.';
  }
}
