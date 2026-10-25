import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/infrastructure/datasources/http_runtime_assistant_datasource.dart';

// Deckt das Standalone-Pendant zu FirebaseFunctionsAssistantDatasource ab:
// gleicher Anfrage-/Antwort-Vertrag, nur über die lokale Runtime-API.
void main() {
  group('HttpRuntimeTaskBuilderAssistantDatasource', () {
    test('spricht den Aufgabenstudio-Endpunkt an', () async {
      final client = _FakeApiClient();
      final datasource = HttpRuntimeTaskBuilderAssistantDatasource(client);

      await datasource.ask(history: const [], question: 'Wie geht das?');

      expect(client.lastPath, '/v1/assistant/task-builder');
    });
  });

  group('HttpRuntimeKnowledgeBaseAssistantDatasource', () {
    test('spricht den Wissensbasis-Endpunkt an', () async {
      final client = _FakeApiClient();
      final datasource = HttpRuntimeKnowledgeBaseAssistantDatasource(client);

      await datasource.ask(
        history: const [],
        question: 'Was steht in der Notiz?',
      );

      expect(client.lastPath, '/v1/assistant/knowledge-base');
    });
  });

  test('schickt die Frage getrennt und den bisherigen Verlauf ohne die '
      'gerade gestellte Frage', () async {
    final client = _FakeApiClient();
    final datasource = HttpRuntimeTaskBuilderAssistantDatasource(client);
    final history = [
      AssistantMessage.user('Erste Frage'),
      AssistantMessage.agent('Erste Antwort'),
      AssistantMessage.user('Zweite Frage'),
    ];

    await datasource.ask(history: history, question: 'Zweite Frage');

    final body = client.lastBody!;
    expect(body['question'], 'Zweite Frage');
    expect(body['history'], [
      {'role': 'user', 'text': 'Erste Frage'},
      {'role': 'agent', 'text': 'Erste Antwort'},
    ]);
  });

  test(
    'gibt die Antwort als JSON-Text weiter, den der Parser lesen kann',
    () async {
      final client = _FakeApiClient(
        response: const {
          'answer': 'Hallo',
          'commands': <Object?>[],
          'knowledgeCommands': <Object?>[],
        },
      );
      final datasource = HttpRuntimeTaskBuilderAssistantDatasource(client);

      final response = await datasource.ask(
        history: const [],
        question: 'Frage',
      );

      expect((jsonDecode(response.text) as Map)['answer'], 'Hallo');
    },
  );

  test('wartet auf den KI-Agenten länger als die Runtime auf das Relay '
      '(125 s)', () async {
    final client = _FakeApiClient();
    final datasource = HttpRuntimeTaskBuilderAssistantDatasource(client);

    await datasource.ask(history: const [], question: 'Hallo');

    expect(client.lastTimeout, assistantRequestTimeout);
    expect(client.lastTimeout! > const Duration(seconds: 125), isTrue);
  });

  test('weist eine Antwort ohne answer-Feld zurück', () async {
    final client = _FakeApiClient(response: const {'unerwartet': true});
    final datasource = HttpRuntimeTaskBuilderAssistantDatasource(client);

    expect(
      () => datasource.ask(history: const [], question: 'Frage'),
      throwsA(isA<StateError>()),
    );
  });
}

class _FakeApiClient implements WorkspaceApiClient {
  _FakeApiClient({
    this.response = const {
      'answer': 'ok',
      'commands': <Object?>[],
      'knowledgeCommands': <Object?>[],
    },
  });

  final Map<String, Object?> response;
  String? lastPath;
  Map<String, Object?>? lastBody;
  Duration? lastTimeout;

  @override
  Future<Map<String, Object?>> postWithTimeout(
    String path,
    Map<String, Object?> body, {
    required Duration timeout,
  }) {
    lastTimeout = timeout;
    return post(path, body);
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    lastPath = path;
    lastBody = body;
    return response;
  }

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) => throw UnimplementedError();
}
