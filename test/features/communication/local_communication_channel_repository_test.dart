import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
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
    final repository = LocalCommunicationChannelRepository(_FakeClient([]));

    expect(await repository.watchChannels().first, isEmpty);
  });

  test('fragt regelmäßig nach, solange jemand zuhört', () {
    fakeAsync((async) {
      final client = _FakeClient([_active]);
      final repository = LocalCommunicationChannelRepository(
        client,
        pollInterval: const Duration(seconds: 15),
      );
      final emissions = <int>[];
      final subscription = repository.watchChannels().listen(
        (channels) => emissions.add(channels.length),
      );

      async.elapse(const Duration(seconds: 1));
      expect(client.gets, 1, reason: 'sofort beim Abonnieren');
      client.items = [
        _active,
        {..._active, 'id': 'c2'},
      ];
      async.elapse(const Duration(seconds: 15));
      expect(emissions, [1, 2]);

      subscription.cancel();
      async.elapse(const Duration(minutes: 5));
      expect(
        client.gets,
        2,
        reason: 'nach dem Abbestellen keine Anfragen mehr',
      );
    });
  });

  test('Fehler der Runtime erreichen den Abonnenten', () async {
    final client = _FakeClient([])..failure = StateError('offline');
    final repository = LocalCommunicationChannelRepository(client);

    await expectLater(repository.watchChannels().first, throwsStateError);
  });

  test('eine ungültige Antwort wird als Fehler gemeldet', () async {
    final repository = LocalCommunicationChannelRepository(
      _FakeClient('kaputt'),
    );

    await expectLater(
      repository.watchChannels().first,
      throwsA(isA<FormatException>()),
    );
  });

  test('startet die Microsoft-Anmeldung über die Runtime', () async {
    final client = _FakeClient([])
      ..postResponse = {'authorizationUrl': 'https://login.example/auth'};
    final repository = LocalCommunicationChannelRepository(client);

    expect(
      await repository.beginMicrosoftConnection(),
      'https://login.example/auth',
    );
    expect(client.posts, ['/v1/mail-connectors/microsoft/authorization']);
  });

  test('eine Antwort ohne Anmelde-Adresse ist ein Fehler', () async {
    final repository = LocalCommunicationChannelRepository(_FakeClient([]));

    await expectLater(repository.beginMicrosoftConnection(), throwsStateError);
  });

  test('WhatsApp, SMS und Testnachrichten gibt es lokal nicht', () async {
    final repository = LocalCommunicationChannelRepository(_FakeClient([]));

    await expectLater(repository.deleteChannel('x'), throwsUnsupportedError);
    await expectLater(
      repository.dispatchFakeMessage('x'),
      throwsUnsupportedError,
    );
  });
}
