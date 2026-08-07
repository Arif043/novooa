import '../../domain/entities/mail_connector.dart';

enum MailConnectorsLoadStatus { loading, ready, failure }

class MailConnectorsState {
  const MailConnectorsState({
    this.status = MailConnectorsLoadStatus.loading,
    this.connectors = const [],
    this.isConnecting = false,
    this.message,
  });

  final MailConnectorsLoadStatus status;
  final List<MailConnector> connectors;
  final bool isConnecting;
  final String? message;

  MailConnectorsState copyWith({
    MailConnectorsLoadStatus? status,
    List<MailConnector>? connectors,
    bool? isConnecting,
    String? message,
  }) {
    return MailConnectorsState(
      status: status ?? this.status,
      connectors: connectors ?? this.connectors,
      isConnecting: isConnecting ?? this.isConnecting,
      message: message,
    );
  }
}
