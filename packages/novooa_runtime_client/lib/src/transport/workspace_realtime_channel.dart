import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'workspace_api_client.dart';

/// Hält genau eine WebSocket-Verbindung zu `/v1/realtime` und multiplext
/// beliebig viele Topic-Abonnements darüber.
///
/// Authentifizierung läuft über ein kurzlebiges Einmal-Ticket
/// (`POST /v1/realtime/ticket`, über den bereits authentifizierten
/// [WorkspaceApiClient]) statt über das langlebige Session-Token direkt —
/// Browser-`WebSocket` kann beim Verbindungsaufbau keine eigenen Header
/// setzen, ein 30 Tage gültiges Token in der URL wäre also ein Risiko
/// (Server-/Proxy-Logs). Ein Ticket ist nach 10 Sekunden oder einmaligem
/// Gebrauch wertlos.
///
/// Trägt bewusst keine Fachdaten über die Verbindung — nur ein leichtes
/// "Topic X hat sich geändert". Wer die Daten selbst braucht, ruft nach dem
/// Signal denselben `load()` erneut auf, den er auch fürs Polling nutzen
/// würde (siehe `watchWorkspaceChannel` in `workspace_api_client.dart`).
class WorkspaceRealtimeChannel {
  WorkspaceRealtimeChannel(this._baseUri, this._client);

  final Uri _baseUri;
  final WorkspaceApiClient _client;

  final Map<String, StreamController<void>> _controllersByTopic = {};
  final Set<String> _subscribedTopics = {};
  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _socketSubscription;
  Future<void>? _connecting;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  bool _disposed = false;

  /// Signalisiert (ohne Nutzdaten), sobald sich [topic] serverseitig
  /// geändert hat. Baut die Verbindung bei Bedarf lazy auf und hält sie
  /// offen, solange mindestens ein Topic beobachtet wird. Hebt eine zuvor
  /// per [close] beendete Verbindung wieder auf — nach einem Abmelden mit
  /// anschließender erneuter Anmeldung in derselben, wiederverwendeten
  /// App-Instanz (siehe `RuntimeConnectionGate`) entstehen frische
  /// Repository-Objekte, deren erster `watch()`-Aufruf die Verbindung mit
  /// einem frischen Ticket neu aufbauen soll.
  Stream<void> watch(String topic) {
    _disposed = false;
    final existing = _controllersByTopic[topic];
    if (existing != null) return existing.stream;
    late final StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () => unawaited(_ensureSubscribed(topic)),
      onCancel: () => _controllersByTopic.remove(topic),
    );
    _controllersByTopic[topic] = controller;
    return controller.stream;
  }

  /// Trennt die aktuelle Verbindung und verwirft alle Abonnements — z.B.
  /// beim Abmelden, damit kein Socket mit einem ungültig gewordenen Token
  /// weiterbesteht oder sich neu verbindet. Die Instanz selbst bleibt
  /// benutzbar: [watch] baut die Verbindung bei Bedarf neu auf (siehe dort).
  Future<void> close() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _connecting = null;
    await _socketSubscription?.cancel();
    await _socket?.sink.close();
    _socket = null;
    _subscribedTopics.clear();
    for (final controller in _controllersByTopic.values) {
      unawaited(controller.close());
    }
    _controllersByTopic.clear();
  }

  Future<void> _ensureSubscribed(String topic) async {
    await _ensureConnected();
    _subscribeTopic(topic);
  }

  /// Sendet ein `subscribe` für [topic] höchstens einmal pro Verbindung.
  /// Ohne diese Sperre würde ein Topic, das gerade erst den (ersten) Connect
  /// ausgelöst hat, doppelt abonniert: einmal durch die
  /// „alle bekannten Topics neu abonnieren“-Schleife in [_connect] und
  /// einmal durch den expliziten Aufruf direkt danach.
  void _subscribeTopic(String topic) {
    if (!_subscribedTopics.add(topic)) return;
    _send({'type': 'subscribe', 'topic': topic});
  }

  Future<void> _ensureConnected() {
    final connecting = _connecting;
    if (connecting != null) return connecting;
    final future = _connect();
    _connecting = future;
    return future;
  }

  /// Fängt jeden Fehler beim Verbindungsaufbau selbst ab (Ticket-Abruf,
  /// Handshake) und plant stattdessen einen erneuten Versuch — sonst bliebe
  /// `_connecting` auf einem abgelehnten Future stehen und jeder spätere
  /// `watch()`-Aufruf würde denselben, längst gescheiterten Versuch
  /// zurückbekommen, ohne dass je wieder neu verbunden würde.
  Future<void> _connect() async {
    if (_disposed) return;
    try {
      final ticket = await _fetchTicket();
      if (_disposed) return;
      final socket = WebSocketChannel.connect(_realtimeUri(ticket));
      _socket = socket;
      _subscribedTopics.clear();
      _socketSubscription = socket.stream.listen(
        _onMessage,
        onError: (Object _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      await socket.ready;
      _reconnectAttempt = 0;
      for (final topic in _controllersByTopic.keys) {
        _subscribeTopic(topic);
      }
    } on Object {
      _scheduleReconnect();
    }
  }

  Future<String> _fetchTicket() async {
    final response = await _client.post('/v1/realtime/ticket', const {});
    final ticket = response['ticket'];
    if (ticket is! String || ticket.isEmpty) {
      throw const FormatException('Kein Realtime-Ticket erhalten.');
    }
    return ticket;
  }

  Uri _realtimeUri(String ticket) {
    return Uri(
      scheme: _baseUri.scheme == 'https' ? 'wss' : 'ws',
      host: _baseUri.host,
      port: _baseUri.port,
      path: '/v1/realtime',
      queryParameters: {'ticket': ticket},
    );
  }

  void _onMessage(Object? raw) {
    if (raw is! String) return;
    try {
      final message = jsonDecode(raw);
      if (message is! Map || message['type'] != 'changed') return;
      final topic = message['topic'];
      if (topic is! String) return;
      _controllersByTopic[topic]?.add(null);
    } on FormatException {
      // Unerwartete Nachricht ignorieren, statt die Verbindung abzubrechen.
    }
  }

  void _send(Map<String, Object?> message) {
    _socket?.sink.add(jsonEncode(message));
  }

  void _scheduleReconnect() {
    _connecting = null;
    _socket = null;
    if (_disposed || _controllersByTopic.isEmpty) return;
    _reconnectTimer?.cancel();
    final delay = Duration(
      seconds: [1, 2, 4, 8, 16, 30][_reconnectAttempt.clamp(0, 5)],
    );
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () {
      if (_disposed || _controllersByTopic.isEmpty) return;
      unawaited(_ensureConnected());
    });
  }
}

/// Watch-Endpunkte mit Realtime-Kanal: Es wird nicht im Takt gefragt, sondern
/// nur nach einem `changed`-Signal von [channel] (oder einmalig beim ersten Listener)
/// [load] erneut aufgerufen. Ein während eines laufenden `load()` erneut
/// eintreffendes Signal wird nicht verworfen, sondern nach dessen Ende genau
/// einmal nachgeholt — so bleibt am Ende immer der aktuellste Stand geladen,
/// ohne überlappende Anfragen.
Stream<T> watchWorkspaceChannel<T>(
  String topic,
  Future<T> Function() load,
  WorkspaceRealtimeChannel channel,
) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;
  var isLoading = false;
  var reloadPending = false;

  Future<void> reload() async {
    if (isLoading) {
      reloadPending = true;
      return;
    }
    isLoading = true;
    try {
      controller.add(await load());
    } on Object catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    } finally {
      isLoading = false;
    }
    if (reloadPending) {
      reloadPending = false;
      unawaited(reload());
    }
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(reload());
      subscription = channel.watch(topic).listen((_) => unawaited(reload()));
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
