import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:syscat2/core/network/secure_transport/secure_channel.dart';
import 'package:syscat2/core/network/secure_transport/secure_workspace_transport.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';

// Gemeinsamer Testvektor mit dem Backend
// (functions/src/shared/local/secure-transport.test.ts).
List<int> _bytes(int start) => List.generate(32, (index) => start + index);
const _clientPublic =
    '07a37cbc142093c8b755dc1b10e86cb426374ad16aa853ed0bdfc0b2b86d1c7c';
const _serverPublic =
    '5714769d116bf76436ae74bc793d2c30ad1903c59ac5273805c7e2698b410c36';
const _clientToServer =
    'ff99147472428379a96929b575f57564a97ea7ec35d90c77f9ce3e75344d31fc';
const _serverToClient =
    'a30822dc5589eb6d32b19427609f0408d25b0e735e8aa9e53a6224b7433a1840';
// Von der jeweils anderen Seite erzeugte Umschläge (Node bzw. Dart).
const _envelopeFromNode =
    'p3ug0kDzPyK8otNuW8riEOhJ4A55Tcjqx2ub4U09iNulfa0yV/zLB4JrCYMxChI=';

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

List<int> _fromHex(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];

Future<SimpleKeyPair> _keyPair(int start) =>
    DartX25519().newKeyPairFromSeed(_bytes(start));

void main() {
  group('Krypto (Interop mit dem Backend)', () {
    test(
      'leitet aus dem Testvektor dieselben Schlüssel ab wie das Backend',
      () async {
        final client = await _keyPair(1);
        final server = await _keyPair(101);

        expect(_hex((await client.extractPublicKey()).bytes), _clientPublic);
        expect(_hex((await server.extractPublicKey()).bytes), _serverPublic);

        final keys = await deriveSessionKeys(
          keyPair: client,
          serverPublicKey: _fromHex(_serverPublic),
          clientNonce: List.filled(16, 0xa1),
          serverNonce: List.filled(16, 0xb2),
        );
        final fromServer = await deriveSessionKeys(
          keyPair: server,
          serverPublicKey: _fromHex(_clientPublic),
          clientNonce: List.filled(16, 0xa1),
          serverNonce: List.filled(16, 0xb2),
        );

        expect(_hex(await keys.clientToServer.extractBytes()), _clientToServer);
        expect(_hex(await keys.serverToClient.extractBytes()), _serverToClient);
        expect(
          await fromServer.clientToServer.extractBytes(),
          await keys.clientToServer.extractBytes(),
        );
      },
    );

    test('öffnet einen vom Backend erzeugten Umschlag', () async {
      final plain = await open(
        SecretKey(_fromHex(_clientToServer)),
        _envelopeFromNode,
        additionalData('abc', TransportDirection.request, 7),
      );

      expect(utf8.decode(plain), '{"hello":"Welt ü"}');
    });

    test(
      'Umschläge sind bei Veränderung oder falschen Zusatzdaten unbrauchbar',
      () async {
        final key = SecretKey(_bytes(7));
        final aad = additionalData('kanal', TransportDirection.request, 1);
        final envelope = await seal(key, utf8.encode('geheim'), aad);
        final raw = base64.decode(envelope)..[14] ^= 1;

        expect(utf8.decode(await open(key, envelope, aad)), 'geheim');
        await expectLater(
          open(key, base64.encode(raw), aad),
          throwsA(anything),
        );
        await expectLater(
          open(
            key,
            envelope,
            additionalData('kanal', TransportDirection.response, 1),
          ),
          throwsA(anything),
        );
        await expectLater(
          open(
            key,
            envelope,
            additionalData('kanal', TransportDirection.request, 2),
          ),
          throwsA(anything),
        );
        await expectLater(
          open(key, 'AAAA', aad),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('jede Nachricht bekommt einen eigenen IV', () async {
      final key = SecretKey(_bytes(7));
      final aad = additionalData('kanal', TransportDirection.request, 1);

      expect(await seal(key, [1], aad), isNot(await seal(key, [1], aad)));
    });
  });

  group('Transport gegen einen Server im Speicher', () {
    late _FakeRuntime runtime;
    late SecureWorkspaceTransport transport;

    setUp(() {
      runtime = _FakeRuntime();
      transport = SecureWorkspaceTransport(
        baseUri: Uri.parse('http://runtime.test/'),
        client: MockClient(runtime.handle),
      );
    });

    Future<SecureResponse> get(String url) => transport.send(
      method: 'GET',
      url: url,
      headers: const {'authorization': 'Bearer geheimes-token'},
      body: null,
    );

    test('handelt einmal aus und tunnelt danach jede Anfrage', () async {
      final first = await get('/v1/echo?a=1');
      await get('/v1/echo');

      expect(first.statusCode, 200);
      expect(jsonDecode(first.body), {
        'method': 'GET',
        'url': '/v1/echo?a=1',
        'authorization': 'Bearer geheimes-token',
        'body': null,
      });
      expect(runtime.handshakes, 1);
      expect(runtime.counters, [1, 2]);
    });

    test('im Netz erscheinen weder Token noch Pfad', () async {
      await get('/v1/echo?secret=abc');

      for (final secret in ['geheimes-token', 'echo', 'secret', 'Bearer']) {
        expect(runtime.wire.join(), isNot(contains(secret)), reason: secret);
      }
      expect(runtime.paths.toSet(), {
        '/v1/secure/handshake',
        '/v1/secure/exchange',
      });
    });

    test('parallele Anfragen bekommen verschiedene Zähler', () async {
      await Future.wait([get('/v1/a'), get('/v1/b'), get('/v1/c')]);

      expect(runtime.handshakes, 1, reason: 'ein gemeinsamer Handshake');
      expect(runtime.counters.toSet(), {1, 2, 3});
    });

    test(
      'verhandelt neu, wenn die Runtime den Kanal nicht mehr kennt',
      () async {
        await get('/v1/echo');
        runtime.forgetChannels();

        final response = await get('/v1/echo');

        expect(response.statusCode, 200);
        expect(runtime.handshakes, 2);
      },
    );

    test(
      'fällt nie still auf Klartext zurück, wenn der Handshake fehlt',
      () async {
        final old = _FakeRuntime(supportsTransport: false);
        final oldTransport = SecureWorkspaceTransport(
          baseUri: Uri.parse('http://runtime.test/'),
          client: MockClient(old.handle),
        );

        await expectLater(
          oldTransport.send(
            method: 'GET',
            url: '/v1/echo',
            headers: const {},
            body: null,
          ),
          throwsA(isA<SecureTransportException>()),
        );
        expect(old.paths, ['/v1/secure/handshake']);
      },
    );

    test('eine manipulierte Antwort wird nicht akzeptiert', () async {
      runtime.corruptResponses = true;

      await expectLater(get('/v1/echo'), throwsA(anything));
    });
  });

  group('HttpWorkspaceApiClient', () {
    test(
      'tunnelt /v1-Anfragen über http und liefert das JSON der Route',
      () async {
        final runtime = _FakeRuntime();
        final client = HttpWorkspaceApiClient(
          baseUri: Uri.parse('http://192.168.1.5:8090'),
          client: MockClient(runtime.handle),
          authHeaderProvider: () async => 'Bearer geheimes-token',
        );

        final result = await client.post('/v1/items', {'name': 'Bericht'});

        expect(result['method'], 'POST');
        expect(result['authorization'], 'Bearer geheimes-token');
        expect(result['body'], '{"name":"Bericht"}');
        expect(runtime.wire.join(), isNot(contains('Bericht')));
      },
    );

    test(
      'Fehlerstatus der Route kommen als WorkspaceHttpException an',
      () async {
        final runtime = _FakeRuntime();
        final client = HttpWorkspaceApiClient(
          baseUri: Uri.parse('http://runtime.test'),
          client: MockClient(runtime.handle),
        );

        await expectLater(
          client.get('/v1/fehler'),
          throwsA(
            isA<WorkspaceHttpException>()
                .having((e) => e.statusCode, 'status', 403)
                .having((e) => e.message, 'message', 'Nicht erlaubt.'),
          ),
        );
      },
    );

    test('Anfragen außerhalb von /v1 bleiben im Klartext', () async {
      final runtime = _FakeRuntime();
      final client = HttpWorkspaceApiClient(
        baseUri: Uri.parse('http://runtime.test'),
        client: MockClient(runtime.handle),
      );

      final result = await client.get('/healthz');

      expect(result, {'status': 'ok'});
      expect(runtime.paths, ['/healthz']);
    });

    test('https braucht keinen eigenen Tunnel', () async {
      final runtime = _FakeRuntime();
      final client = HttpWorkspaceApiClient(
        baseUri: Uri.parse('https://novooa.example.de'),
        client: MockClient(runtime.handle),
      );

      await client.get('/v1/echo');

      expect(runtime.paths, ['/v1/echo']);
    });

    test('der Tunnel lässt sich ausschalten', () async {
      final runtime = _FakeRuntime();
      final client = HttpWorkspaceApiClient(
        baseUri: Uri.parse('http://runtime.test'),
        client: MockClient(runtime.handle),
        encryptPlainHttp: false,
      );

      await client.get('/v1/echo');

      expect(runtime.paths, ['/v1/echo']);
    });

    test('ein Handshake-Fehler wird zur Verbindungsstörung', () async {
      final runtime = _FakeRuntime(supportsTransport: false);
      final client = HttpWorkspaceApiClient(
        baseUri: Uri.parse('http://runtime.test'),
        client: MockClient(runtime.handle),
      );

      await expectLater(
        client.get('/v1/echo'),
        throwsA(isA<WorkspaceConnectionException>()),
      );
    });
  });
}

/// Eine Runtime im Speicher, die das Protokoll des Backends mit denselben
/// Primitiven nachbildet.
class _FakeRuntime {
  _FakeRuntime({this.supportsTransport = true});

  final bool supportsTransport;
  bool corruptResponses = false;
  int handshakes = 0;
  final counters = <int>[];
  final paths = <String>[];
  final wire = <String>[];
  final _channels = <String, SessionKeys>{};

  void forgetChannels() => _channels.clear();

  Future<http.Response> handle(http.Request request) async {
    paths.add(request.url.path);
    wire.add('${request.url}${request.body}');
    switch (request.url.path) {
      case '/healthz':
        return _json({'status': 'ok'});
      case '/v1/secure/handshake':
        return supportsTransport
            ? _handshake(request)
            : http.Response('{}', 404);
      case '/v1/secure/exchange':
        return _exchange(request);
      default:
        return _json({'method': request.method, 'url': request.url.path});
    }
  }

  Future<http.Response> _handshake(http.Request request) async {
    handshakes++;
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final serverPair = await DartX25519().newKeyPair();
    final serverNonce = List.filled(16, 0x42);
    final clientNonce = base64.decode(body['clientNonce']! as String);
    final keys = await deriveSessionKeys(
      keyPair: serverPair,
      serverPublicKey: base64.decode(body['clientPublicKey']! as String),
      clientNonce: clientNonce,
      serverNonce: serverNonce,
    );
    final id = 'kanal-$handshakes';
    _channels[id] = keys;
    return _json({
      'version': 1,
      'channelId': id,
      'serverPublicKey': base64.encode(
        (await serverPair.extractPublicKey()).bytes,
      ),
      'serverNonce': base64.encode(serverNonce),
    });
  }

  Future<http.Response> _exchange(http.Request request) async {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final id = body['channelId']! as String;
    final keys = _channels[id];
    if (keys == null) {
      return http.Response(jsonEncode({'code': 'secure_channel_unknown'}), 404);
    }
    final counter = body['counter']! as int;
    counters.add(counter);
    final plain = await open(
      keys.clientToServer,
      body['payload']! as String,
      additionalData(id, TransportDirection.request, counter),
    );
    final inner = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final reply = _route(inner);
    var payload = await seal(
      keys.serverToClient,
      utf8.encode(jsonEncode(reply)),
      additionalData(id, TransportDirection.response, counter),
    );
    if (corruptResponses) {
      final raw = base64.decode(payload)..[20] ^= 1;
      payload = base64.encode(raw);
    }
    return _json({'payload': payload});
  }

  Map<String, Object?> _route(Map<String, Object?> inner) {
    final url = inner['url']! as String;
    if (url == '/v1/fehler') {
      return {
        'status': 403,
        'contentType': 'application/json',
        'body': '{"error":"Nicht erlaubt."}',
      };
    }
    final headers = inner['headers']! as Map<String, Object?>;
    return {
      'status': 200,
      'contentType': 'application/json',
      'body': jsonEncode({
        'method': inner['method'],
        'url': url,
        'authorization': headers['authorization'],
        'body': inner['body'],
      }),
    };
  }

  http.Response _json(Map<String, Object?> body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
