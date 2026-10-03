import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_defaults.dart';
import 'package:syscat2/features/language_models/infrastructure/repositories/local_language_model_defaults_repository.dart';

// `watchWorkspaceChannel` lädt beim ersten Listener sofort per `load()` —
// unabhängig davon, ob der Realtime-Kanal erfolgreich verbindet. Für diese
// Mapping-Tests reicht daher ein Kanal auf eine unerreichbare Adresse, mit
// einem eigenen, nicht-aufzeichnenden Client für den Ticket-Abruf — sonst
// würde dessen `POST /v1/realtime/ticket` die Aufzeichnung der eigentlichen
// `_RecordingClient`-Testdouble überschreiben.
WorkspaceRealtimeChannel _fakeChannel() =>
    WorkspaceRealtimeChannel(Uri.parse('http://127.0.0.1:0'), _NoopClient());

void main() {
  test('lädt die gespeicherten Vorgaben über die Runtime-API', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelDefaultsRepository(
      client,
      _fakeChannel(),
    );

    final defaults = await repository
        .watchLanguageModelDefaults(const TeamId('team-1'))
        .first;

    expect(client.getPath, '/v1/language-model-defaults');
    expect(defaults.blockModelId, 'model-1');
  });

  test('speichert die Vorgabe über PUT', () async {
    final client = _RecordingClient();
    final repository = LocalLanguageModelDefaultsRepository(
      client,
      _fakeChannel(),
    );

    await repository.saveLanguageModelDefaults(
      const TeamId('team-1'),
      const LanguageModelDefaults(blockModelId: 'model-1'),
    );

    expect(client.putPath, '/v1/language-model-defaults');
    expect(client.putBody, {'blockModelId': 'model-1'});
  });
}

class _RecordingClient extends WorkspaceApiClient {
  String? getPath;
  String? putPath;
  Map<String, Object?>? putBody;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async {
    getPath = path;
    return {'blockModelId': 'model-1'};
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async {
    putPath = path;
    putBody = body;
    return const {};
  }
}

class _NoopClient extends WorkspaceApiClient {
  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
