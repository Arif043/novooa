import '../../domain/entities/language_model_connection.dart';

enum LanguageModelConnectionsStatus { loading, ready, failure }

class LanguageModelConnectionsState {
  const LanguageModelConnectionsState({
    this.status = LanguageModelConnectionsStatus.loading,
    this.connections = const [],
    this.message,
  });

  final LanguageModelConnectionsStatus status;
  final List<LanguageModelConnection> connections;
  final String? message;

  LanguageModelConnectionsState copyWith({
    LanguageModelConnectionsStatus? status,
    List<LanguageModelConnection>? connections,
    String? message,
  }) {
    return LanguageModelConnectionsState(
      status: status ?? this.status,
      connections: connections ?? this.connections,
      message: message,
    );
  }
}
