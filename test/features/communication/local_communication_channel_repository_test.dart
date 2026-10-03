import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/infrastructure/repositories/local_communication_channel_repository.dart';

class _FakeClient extends WorkspaceApiClient {
  _FakeClient(this.items);

  Object items;
  int gets = 0;
  final posts = <String>[];
  Map<String, Object?> postResponse = const {};
  Object? failure;

  @override
  Future<Map<String, Object?>> get(String path) async {
    gets++;
    if (failure != null) throw failure!;
    expect(path, '/v1/mail-connectors');
    return {'items': items};
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    posts.add(path);
    return postResponse;
  }

  @override
  Future<Map<String, Object?>> delete(String path) =>
      throw UnimplementedError();

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      throw UnimplementedError();
}

class _FakeChannel implements WorkspaceRealtimeChannel {
  final _changes = StreamController<void>.broadcast();
  final topics = <String>[];

  void signal() => _changes.add(null);

  @override
  Stream<void> watch(String topic) {
    topics.add(topic);
    return _changes.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _active = {
  'id': 'c1',
  'teamId': 'workspace-1',
  'emailAddress': 'team@example.com',
  'displayName': 'Team Postfach',
  'status': 'active',
};

void main() {
  test('wandelt die Postfächer der Runtime in E-Mail-Kanäle um', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient([
        _active,
        {..._active, 'id': 'c2', 'status': 'reauthorizationRequired'},
        {..._active, 'id': 'c3', 'status': 'disconnected'},
      ]),
      _FakeChannel(),
    );

    final channels = await repository.watchChannels().first;

    expect(channels.map((channel) => channel.id), ['c1', 'c2', 'c3']);
    final first = channels.first;
    expect(first.kind, CommunicationChannelKind.email);
    expect(first.provider, CommunicationProvider.microsoftGraph);
    expect(first.label, 'Team Postfach');
    expect(first.address, 'team@example.com');
    expect(first.teamId.value, 'workspace-1');
    expect(first.connectorId, 'c1');
    expect(first.isActive, isTrue);
    expect(channels[1].needsReconnection, isTrue);
    expect(channels[2].status, CommunicationChannelStatus.disabled);
  });

  test('ohne Postfächer ist die Liste leer', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient([]),
      _FakeChannel(),
    );

    expect(await repository.watchChannels().first, isEmpty);
  });

  test(
    'lädt beim Abonnieren und danach nur auf ein Signal der Runtime',
    () async {
      final client = _FakeClient([_active]);
      final channel = _FakeChannel();
      final repository = LocalCommunicationChannelRepository(client, channel);
      final emissions = <int>[];
      final subscription = repository.watchChannels().listen(
        (channels) => emissions.add(channels.length),
      );

      await pumpEventQueue();
      expect(client.gets, 1, reason: 'sofort beim Abonnieren');
      expect(channel.topics, ['mail-connectors']);

      await pumpEventQueue(times: 50);
      expect(client.gets, 1, reason: 'ohne Signal keine weitere Anfrage');

      client.items = [
        _active,
        {..._active, 'id': 'c2'},
      ];
      channel.signal();
      await pumpEventQueue();
      expect(emissions, [1, 2]);

      await subscription.cancel();
    },
  );

  test('Fehler der Runtime erreichen den Abonnenten', () async {
    final client = _FakeClient([])..failure = StateError('offline');
    final repository = LocalCommunicationChannelRepository(
      client,
      _FakeChannel(),
    );

    await expectLater(repository.watchChannels().first, throwsStateError);
  });

  test('eine ungültige Antwort wird als Fehler gemeldet', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient('kaputt'),
      _FakeChannel(),
    );

    await expectLater(
      repository.watchChannels().first,
      throwsA(isA<FormatException>()),
    );
  });

  test('startet die Microsoft-Anmeldung über die Runtime', () async {
    final client = _FakeClient([])
      ..postResponse = {'authorizationUrl': 'https://login.example/auth'};
    final repository = LocalCommunicationChannelRepository(
      client,
      _FakeChannel(),
    );

    expect(
      await repository.beginMicrosoftConnection(),
      'https://login.example/auth',
    );
    expect(client.posts, ['/v1/mail-connectors/microsoft/authorization']);
  });

  test('eine Antwort ohne Anmelde-Adresse ist ein Fehler', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient([]),
      _FakeChannel(),
    );

    await expectLater(repository.beginMicrosoftConnection(), throwsStateError);
  });

  test('WhatsApp, SMS und Testnachrichten gibt es lokal nicht', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient([]),
      _FakeChannel(),
    );

    await expectLater(repository.deleteChannel('x'), throwsUnsupportedError);
    await expectLater(
      repository.dispatchFakeMessage('x'),
      throwsUnsupportedError,
    );
  });
}
