import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/speech_synthesis/domain/entities/speech_voice.dart';
import 'package:syscat2/features/speech_synthesis/domain/repositories/speech_voice_repository.dart';
import 'package:syscat2/features/speech_synthesis/domain/usecases/list_speech_voices.dart';
import 'package:syscat2/features/speech_synthesis/infrastructure/repositories/local_speech_voice_repository.dart';
import 'package:syscat2/features/speech_synthesis/presentation/cubits/speech_voices_cubit.dart';
import 'package:syscat2/features/speech_synthesis/presentation/cubits/speech_voices_state.dart';

void main() {
  test('liest die Stimmenliste der lokalen Runtime', () async {
    final client = _FakeApiClient({
      'voices': [
        {'id': 'Kore', 'name': 'Kore', 'description': 'Bestimmt'},
        {'id': 'v2', 'name': 'Hans', 'language': 'de'},
      ],
      'defaultVoiceId': 'Kore',
      'allowsCustomVoice': true,
    });

    final list = await LocalSpeechVoiceRepository(client).listVoices('lm 1/x');

    expect(client.lastPath, '/v1/language-models/lm%201%2Fx/voices');
    expect(list.defaultVoiceId, 'Kore');
    expect(list.allowsCustomVoice, isTrue);
    expect(list.voiceById('v2')?.language, 'de');
    expect(list.voiceById('Kore')?.description, 'Bestimmt');
    expect(list.voiceById('fehlt'), isNull);
  });

  test('übernimmt die Meldung des Servers als lesbare Ausnahme', () async {
    final client = _FakeApiClient.failing(
      WorkspaceHttpException(
        400,
        const WorkspaceApiError(message: 'Das Konto hat keine Stimmen.'),
      ),
    );

    await expectLater(
      LocalSpeechVoiceRepository(client).listVoices('lm-1'),
      throwsA(
        isA<SpeechVoicesException>().having(
          (e) => e.message,
          'message',
          'Das Konto hat keine Stimmen.',
        ),
      ),
    );
  });

  test('der Cubit meldet Laden, Erfolg und Fehler samt Wiederholung', () async {
    final repository = _SequenceRepository([
      const SpeechVoicesException('Anbieter nicht erreichbar.'),
      const SpeechVoiceList(
        voices: [SpeechVoice(id: 'a', name: 'A')],
        defaultVoiceId: 'a',
        allowsCustomVoice: false,
      ),
    ]);
    final cubit = SpeechVoicesCubit(ListSpeechVoices(repository), 'lm-1');

    expect(cubit.state.status, SpeechVoicesStatus.loading);
    await cubit.load();
    expect(cubit.state.status, SpeechVoicesStatus.failure);
    expect(cubit.state.message, 'Anbieter nicht erreichbar.');

    await cubit.load();
    expect(cubit.state.status, SpeechVoicesStatus.ready);
    expect(cubit.state.voices?.defaultVoiceId, 'a');
    await cubit.close();
  });
}

class _SequenceRepository implements SpeechVoiceRepository {
  _SequenceRepository(this._results);

  final List<Object> _results;

  @override
  Future<SpeechVoiceList> listVoices(String languageModelId) async {
    final next = _results.removeAt(0);
    if (next is Exception) throw next;
    return next as SpeechVoiceList;
  }
}

class _FakeApiClient implements WorkspaceApiClient {
  _FakeApiClient(this.response) : failure = null;
  _FakeApiClient.failing(this.failure) : response = const {};

  final Map<String, Object?> response;
  final Object? failure;
  String? lastPath;

  @override
  Future<Map<String, Object?>> get(String path) async {
    lastPath = path;
    if (failure != null) throw failure!;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
