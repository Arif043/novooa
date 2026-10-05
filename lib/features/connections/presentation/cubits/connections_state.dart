import 'package:equatable/equatable.dart';

import '../../domain/entities/connection.dart';

enum ConnectionsStatus { loading, ready, failure }

class ConnectionsState extends Equatable {
  const ConnectionsState({
    this.status = ConnectionsStatus.loading,
    this.connections = const [],
    this.message,
  });

  final ConnectionsStatus status;
  final List<Connection> connections;

  /// Einmalige Rückmeldung (Fehler oder Bestätigung) für eine Snackbar.
  final String? message;

  ConnectionsState copyWith({
    ConnectionsStatus? status,
    List<Connection>? connections,
    String? message,
    bool clearMessage = false,
  }) {
    return ConnectionsState(
      status: status ?? this.status,
      connections: connections ?? this.connections,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, connections, message];
}
