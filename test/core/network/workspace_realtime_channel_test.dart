import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

void main() {
  late HttpServer server;
  late List<WebSocket> serverSockets;
  late List<Map<String, Object?>> receivedMessages;

  setUp(() async {
    serverSockets = [];
    receivedMessages = [];
    server = await HttpServer.bind('127.0.0.1', 0);
    unawaited(
      server.forEach((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        serverSockets.add(socket);
        socket.listen((raw) {
          receivedMessages.add(jsonDecode(raw as String) as Map<String, Object?>);
        });
      }),
    );
  });

  tearDown(() async {
    for (final socket in serverSockets) {
      await socket.close();
    }
    await server.close(force: true);
  });

  Uri baseUri() => Uri(scheme: 'http', host: server.address.address, port: server.port);

  void sendChanged(String topic) {
    for (final socket in serverSockets) {
      socket.add(jsonEncode({'type': 'changed', 'topic': topic}));
    }
  }

  test('sendet nach dem Ticket-Abruf eine subscribe-Nachricht', () async {
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());

    final subscription = channel.watch('task-runs').listen((_) {});
    await _waitUntil(() => receivedMessages.isNotEmpty);

    expect(receivedMessages, [
      {'type': 'subscribe', 'topic': 'task-runs'},
    ]);
    await subscription.cancel();
    await channel.close();
  });

  test('liefert ein Signal, wenn der Server "changed" für das Topic schickt', () async {
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());
    var signalCount = 0;
    final subscription = channel.watch('task-runs').listen((_) => signalCount++);
    await _waitUntil(() => serverSockets.isNotEmpty);

    sendChanged('task-runs');
    await _waitUntil(() => signalCount == 1);

    expect(signalCount, 1);
    await subscription.cancel();
    await channel.close();
  });

  test('ignoriert ein "changed" für ein nicht beobachtetes Topic', () async {
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());
    var signalCount = 0;
    final subscription = channel.watch('task-runs').listen((_) => signalCount++);
    await _waitUntil(() => serverSockets.isNotEmpty);

    sendChanged('tasks');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(signalCount, 0);
    await subscription.cancel();
    await channel.close();
  });

  test('watchWorkspaceChannel lädt beim ersten Listener und bei jedem Signal neu', () async {
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());
    var loadCount = 0;
    final stream = watchWorkspaceChannel('task-runs', () async {
      loadCount++;
      return loadCount;
    }, channel);

    final values = <int>[];
    final subscription = stream.listen(values.add);
    await _waitUntil(() => values.isNotEmpty);
    await _waitUntil(() => serverSockets.isNotEmpty);

    sendChanged('task-runs');
    await _waitUntil(() => values.length >= 2);

    expect(values, [1, 2]);
    await subscription.cancel();
    await channel.close();
  });

  test('watchWorkspaceChannel holt bei überlappenden Signalen genau einmal nach', () async {
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());
    final loadStarted = Completer<void>();
    final releaseLoad = Completer<void>();
    var loadCount = 0;
    final stream = watchWorkspaceChannel('task-runs', () async {
      loadCount++;
      if (loadCount == 1) {
        loadStarted.complete();
        await releaseLoad.future;
      }
      return loadCount;
    }, channel);

    final values = <int>[];
    final subscription = stream.listen(values.add);
    await loadStarted.future;
    await _waitUntil(() => serverSockets.isNotEmpty);

    // Zwei Signale, während der erste load() noch läuft — sollen zu genau
    // einem Nachladen zusammengefasst werden, nicht zu zweien.
    sendChanged('task-runs');
    sendChanged('task-runs');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    releaseLoad.complete();
    await _waitUntil(() => values.length >= 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(values, [1, 2]);
    await subscription.cancel();
    await channel.close();
  });

  test('watch() nach close() baut die Verbindung neu auf', () async {
    // Deckt den Abmelden-dann-erneut-anmelden-Ablauf ab (siehe
    // RuntimeConnectionCubit.signOut/RuntimeConnectionGate): dieselbe
    // Singleton-Instanz von WorkspaceRealtimeChannel wird nach einem
    // erzwungenen close() durch eine frische Repository-Instanz erneut
    // beobachtet und muss dann wieder funktionieren, statt dauerhaft
    // stumm zu bleiben.
    final channel = WorkspaceRealtimeChannel(baseUri(), _FakeApiClient());
    var signalCount = 0;
    var subscription = channel.watch('task-runs').listen((_) => signalCount++);
    await _waitUntil(() => serverSockets.isNotEmpty);

    await channel.close();
    await subscription.cancel();

    subscription = channel.watch('task-runs').listen((_) => signalCount++);
    await _waitUntil(() => serverSockets.length >= 2);
    await _waitUntil(() => receivedMessages.length >= 2);

    serverSockets.last.add(jsonEncode({'type': 'changed', 'topic': 'task-runs'}));
    await _waitUntil(() => signalCount == 1);

    expect(signalCount, 1);
    await subscription.cancel();
    await channel.close();
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Bedingung nicht innerhalb von 5s erfüllt.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class _FakeApiClient implements WorkspaceApiClient {
  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) async {
    if (path == '/v1/realtime/ticket') return {'ticket': 'fake-ticket'};
    return const {};
  }

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) async => const {};

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) => throw UnimplementedError();
}
