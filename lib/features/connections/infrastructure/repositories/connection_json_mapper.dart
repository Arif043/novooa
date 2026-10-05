import '../../domain/entities/connection.dart';
import '../../domain/entities/connection_draft.dart';
import '../../domain/entities/connection_test_result.dart';

Map<String, Object?> _record(Object? value, String what) {
  if (value is! Map) throw FormatException('$what ist ungültig.');
  return value.cast<String, Object?>();
}

String _string(Object? value) => value is String ? value : '';

ConnectionAuth authFromJson(Object? value) {
  final json = _record(value, 'Anmeldeart');
  return switch (json['kind']) {
    'apiKey' => ApiKeyAuth(headerName: _string(json['headerName'])),
    'bearer' => const BearerAuth(),
    'oauthClientCredentials' => OAuthClientCredentialsAuth(
      tokenUrl: _string(json['tokenUrl']),
      clientId: _string(json['clientId']),
      scope: _string(json['scope']),
      sendsJson: json['tokenRequestFormat'] == 'json',
    ),
    _ => throw const FormatException('Die Anmeldeart ist unbekannt.'),
  };
}

Map<String, Object?> authToJson(ConnectionAuth auth) {
  return switch (auth) {
    ApiKeyAuth(:final headerName) => {
      'kind': 'apiKey',
      'headerName': headerName,
    },
    BearerAuth() => {'kind': 'bearer'},
    OAuthClientCredentialsAuth(
      :final tokenUrl,
      :final clientId,
      :final scope,
      :final sendsJson,
    ) =>
      {
        'kind': 'oauthClientCredentials',
        'tokenUrl': tokenUrl,
        'clientId': clientId,
        if (scope.trim().isNotEmpty) 'scope': scope.trim(),
        if (sendsJson) 'tokenRequestFormat': 'json',
      },
  };
}

Connection connectionFromJson(Object? value) {
  final json = _record(value, 'Verbindung');
  return Connection(
    id: _string(json['id']),
    name: _string(json['name']),
    baseUrl: _string(json['baseUrl']),
    auth: authFromJson(json['auth']),
    updatedAt: _string(json['updatedAt']),
  );
}

List<Connection> connectionsFromJson(Map<String, Object?> json) {
  final items = json['items'];
  if (items is! List) {
    throw const FormatException('Verbindungen konnten nicht gelesen werden.');
  }
  return items.map(connectionFromJson).toList(growable: false);
}

/// Das Geheimnis wird nur mitgeschickt, wenn eines eingegeben wurde.
Map<String, Object?> draftToJson(ConnectionDraft draft) {
  final secret = draft.secret.trim();
  return {
    'name': draft.name.trim(),
    'baseUrl': draft.baseUrl.trim(),
    'auth': authToJson(draft.auth),
    if (secret.isNotEmpty) 'secret': secret,
  };
}

ConnectionTestResult testResultFromJson(Map<String, Object?> json) {
  return ConnectionTestResult(
    ok: json['ok'] == true,
    message: _string(json['message']),
  );
}
