part of 'node_config.dart';

enum HttpRequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const HttpRequestMethod(this.wire);

  /// So heißt die Methode in der gespeicherten Aufgabe.
  final String wire;

  /// Nur diese Methoden senden einen Body.
  bool get sendsBody => this != get;

  static HttpRequestMethod fromWire(Object? value) =>
      values.firstWhere((method) => method.wire == value, orElse: () => get);
}

enum HttpBodyType {
  none,
  json,
  text;

  static HttpBodyType fromName(Object? value) =>
      values.firstWhere((type) => type.name == value, orElse: () => none);
}

/// Ein Name-Wert-Paar (Query-Parameter oder Header); der Wert darf
/// Template-Ausdrücke enthalten.
class HttpNameValue extends Equatable {
  const HttpNameValue({this.name = '', this.value = ''});

  final String name;
  final String value;

  HttpNameValue copyWith({String? name, String? value}) =>
      HttpNameValue(name: name ?? this.name, value: value ?? this.value);

  @override
  List<Object?> get props => [name, value];
}

/// HTTP-Anfrage an ein externes System. Zugangsdaten stehen nie hier: Mit
/// [connectionId] ergänzt die Runtime die Anmeldung der Verbindung.
class HttpRequestNodeConfig extends NodeConfig {
  const HttpRequestNodeConfig({
    this.connectionId = '',
    this.method = HttpRequestMethod.get,
    this.url = '',
    this.query = const [],
    this.headers = const [],
    this.bodyType = HttpBodyType.none,
    this.body = '',
    this.timeoutSeconds = 30,
    this.failOnHttpError = true,
  });

  factory HttpRequestNodeConfig.initial() => const HttpRequestNodeConfig();

  /// Leer heißt: ohne Verbindung, `url` muss dann vollständig sein.
  final String connectionId;
  final HttpRequestMethod method;
  final String url;
  final List<HttpNameValue> query;
  final List<HttpNameValue> headers;
  final HttpBodyType bodyType;
  final String body;
  final int timeoutSeconds;

  /// Bei einem Status außerhalb von 2xx bricht der Baustein ab; ausgeschaltet
  /// liefert er `status` und `ok` für eine Verzweigung.
  final bool failOnHttpError;

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.httpRequest;

  @override
  List<Object?> get props => [
    connectionId,
    method,
    url,
    query,
    headers,
    bodyType,
    body,
    timeoutSeconds,
    failOnHttpError,
  ];

  HttpRequestNodeConfig copyWith({
    String? connectionId,
    HttpRequestMethod? method,
    String? url,
    List<HttpNameValue>? query,
    List<HttpNameValue>? headers,
    HttpBodyType? bodyType,
    String? body,
    int? timeoutSeconds,
    bool? failOnHttpError,
  }) {
    return HttpRequestNodeConfig(
      connectionId: connectionId ?? this.connectionId,
      method: method ?? this.method,
      url: url ?? this.url,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      bodyType: bodyType ?? this.bodyType,
      body: body ?? this.body,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      failOnHttpError: failOnHttpError ?? this.failOnHttpError,
    );
  }
}
