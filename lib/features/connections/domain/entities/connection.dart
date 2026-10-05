import 'package:equatable/equatable.dart';

/// Wie sich novooa gegenüber dem externen System ausweist. Das zugehörige
/// Geheimnis (Key, Token, Client-Secret) liegt nur im Backend und kommt nie
/// zum Client zurück.
sealed class ConnectionAuth extends Equatable {
  const ConnectionAuth();

  /// Name der Anmeldeart in der Oberfläche.
  String get label;

  /// Wie das Geheimnis dieser Anmeldeart heißt.
  String get secretLabel;
}

class ApiKeyAuth extends ConnectionAuth {
  const ApiKeyAuth({required this.headerName});

  final String headerName;

  @override
  String get label => 'API-Key im Header';

  @override
  String get secretLabel => 'API-Key';

  @override
  List<Object?> get props => [headerName];
}

class BearerAuth extends ConnectionAuth {
  const BearerAuth();

  @override
  String get label => 'Bearer-Token';

  @override
  String get secretLabel => 'Token';

  @override
  List<Object?> get props => const [];
}

class OAuthClientCredentialsAuth extends ConnectionAuth {
  const OAuthClientCredentialsAuth({
    required this.tokenUrl,
    required this.clientId,
    this.scope = '',
  });

  final String tokenUrl;
  final String clientId;

  /// Leer heißt: kein Scope anfordern.
  final String scope;

  @override
  String get label => 'OAuth (Client Credentials)';

  @override
  String get secretLabel => 'Client-Secret';

  @override
  List<Object?> get props => [tokenUrl, clientId, scope];
}

class Connection extends Equatable {
  const Connection({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.auth,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final ConnectionAuth auth;
  final String updatedAt;

  @override
  List<Object?> get props => [id, name, baseUrl, auth, updatedAt];
}
