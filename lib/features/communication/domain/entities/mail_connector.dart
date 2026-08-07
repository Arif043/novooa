import 'package:equatable/equatable.dart';

enum MailConnectorProvider { microsoftGraph }

enum MailConnectorStatus { active, reauthorizationRequired, disconnected }

class MailConnector extends Equatable {
  const MailConnector({
    required this.id,
    required this.emailAddress,
    required this.displayName,
    required this.provider,
    required this.status,
  });

  final String id;
  final String emailAddress;
  final String displayName;
  final MailConnectorProvider provider;
  final MailConnectorStatus status;

  bool get isActive => status == MailConnectorStatus.active;

  @override
  List<Object> get props => [id, emailAddress, displayName, provider, status];
}
