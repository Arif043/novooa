import 'package:equatable/equatable.dart';

import 'connection.dart';

/// Eingaben aus dem Editor. [secret] ist beim Anlegen Pflicht; beim Ändern
/// bedeutet leer „gespeichertes Geheimnis behalten“.
class ConnectionDraft extends Equatable {
  const ConnectionDraft({
    required this.name,
    required this.baseUrl,
    required this.auth,
    this.secret = '',
  });

  final String name;
  final String baseUrl;
  final ConnectionAuth auth;
  final String secret;

  @override
  List<Object?> get props => [name, baseUrl, auth, secret];
}
