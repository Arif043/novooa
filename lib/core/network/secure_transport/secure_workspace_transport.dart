import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secure_channel.dart';

/// Antwort der Runtime auf eine durch den Tunnel geschickte Anfrage.
class SecureResponse {
  const SecureResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// Die Runtime unterstützt den verschlüsselten Transport nicht (zu alt) oder
/// der Austausch ist fehlgeschlagen. Absichtlich kein stiller Rückfall auf
/// Klartext: Sonst könnte ein Angreifer die Verschlüsselung durch eine
/// gefälschte Fehlerantwort abschalten.
class SecureTransportException implements Exception {
  const SecureTransportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _Channel {
  _Channel(this.id, this.keys);

  final String id;
  final SessionKeys keys;
  int counter = 0;
}

/// Schickt Anfragen verschlüsselt durch `POST /v1/secure/exchange`. Der Kanal
/// wird beim ersten Aufruf ausgehandelt und bei Bedarf (Neustart der Runtime,
/// abgelaufener Kanal) einmal neu aufgebaut.
///
/// Schützt gegen passives Mitlesen im Netz. Ein aktiver Man-in-the-Middle
/// beim Handshake wird dadurch nicht ausgeschlossen.
class SecureWorkspaceTransport {
  SecureWorkspaceTransport({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUri = baseUri,
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  Future<_Channel>? _connecting;

  Future<SecureResponse> send({
    required String method,
    required String url,
    required Map<String, String> headers,
    required String? body,
    Duration? timeout,
  }) async {
    final request = jsonEncode({
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
    });
    final exchangeTimeout = timeout ?? this.timeout;
    try {
      return await _exchange(await _channel(), request, exchangeTimeout);
    } on _UnknownChannel {
      _connecting = null;
      return _exchange(await _channel(), request, exchangeTimeout);
    }
  }

  Future<_Channel> _channel() => _connecting ??= _handshake();

  Future<_Channel> _handshake() async {
    try {
      return await _openChannel();
    } catch (_) {
      _connecting = null;
      rethrow;
    }
  }

  Future<_Channel> _openChannel() async {
    final handshake = await ClientHandshake.create();
    final response = await _post('/v1/secure/handshake', {
      'clientPublicKey': base64.encode(handshake.publicKey),
      'clientNonce': base64.encode(handshake.nonce),
    });
    if (response.statusCode == 404) {
      throw const SecureTransportException(
        'Die Runtime unterstützt die verschlüsselte Verbindung nicht. '
        'Bitte aktualisiere die Runtime.',
      );
    }
    final data = _json(response, 'Handshake');
    final keys = await deriveSessionKeys(
      keyPair: handshake.keyPair,
      serverPublicKey: base64.decode(data['serverPublicKey'] as String),
      clientNonce: handshake.nonce,
      serverNonce: base64.decode(data['serverNonce'] as String),
    );
    return _Channel(data['channelId'] as String, keys);
  }

  Future<SecureResponse> _exchange(
    _Channel channel,
    String request,
    Duration timeout,
  ) async {
    final counter = ++channel.counter;
    final payload = await seal(
      channel.keys.clientToServer,
      utf8.encode(request),
      additionalData(channel.id, TransportDirection.request, counter),
    );
    final response = await _post('/v1/secure/exchange', {
      'channelId': channel.id,
      'counter': counter,
      'payload': payload,
    }, timeout: timeout);
    if (response.statusCode == 404) throw _UnknownChannel();
    final data = _json(response, 'Austausch');
    final plain = await open(
      channel.keys.serverToClient,
      data['payload'] as String,
      additionalData(channel.id, TransportDirection.response, counter),
    );
    final inner = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    return SecureResponse(
      statusCode: inner['status'] as int,
      body: inner['body'] as String? ?? '',
    );
  }

  /// Der Handshake bleibt beim Standardlimit; nur der Austausch darf länger.
  Future<http.Response> _post(
    String path,
    Map<String, Object?> body, {
    Duration? timeout,
  }) async {
    final response = await _client
        .post(
          _baseUri.resolve(path.substring(1)),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout ?? this.timeout);
    return response;
  }

  Map<String, Object?> _json(http.Response response, String step) {
    if (response.statusCode != 200) {
      throw SecureTransportException(
        'Verschlüsselte Verbindung ($step) fehlgeschlagen: '
        '${response.statusCode}.',
      );
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }
}

class _UnknownChannel implements Exception {}
