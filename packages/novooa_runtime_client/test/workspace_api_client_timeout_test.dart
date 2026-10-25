import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

HttpWorkspaceApiClient _clientAnsweringAfter(Duration delay) {
  return HttpWorkspaceApiClient(
    baseUri: Uri.parse('http://127.0.0.1:8080/'),
    timeout: const Duration(milliseconds: 20),
    client: MockClient((_) async {
      await Future<void>.delayed(delay);
      return http.Response('{"answer":"ok"}', 200);
    }),
  );
}

void main() {
  const slowAnswer = Duration(milliseconds: 80);

  test('post bricht nach dem Standardlimit ab', () async {
    final client = _clientAnsweringAfter(slowAnswer);

    await expectLater(
      client.post('/v1/assistant/task-builder', const {}),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('postWithTimeout wartet bis zum eigenen Limit', () async {
    final client = _clientAnsweringAfter(slowAnswer);

    final response = await client.postWithTimeout(
      '/v1/assistant/task-builder',
      const {},
      timeout: const Duration(seconds: 2),
    );

    expect(response['answer'], 'ok');
  });

  test('der Sitzungs-Decorator reicht das Zeitlimit weiter', () async {
    final events = RuntimeSessionEvents();
    final client = SessionAwareWorkspaceApiClient(
      _clientAnsweringAfter(slowAnswer),
      events,
    );

    final response = await client.postWithTimeout(
      '/v1/assistant/task-builder',
      const {},
      timeout: const Duration(seconds: 2),
    );

    expect(response['answer'], 'ok');
    await events.close();
  });
}
