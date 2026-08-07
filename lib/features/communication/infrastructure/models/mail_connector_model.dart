import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/mail_connector.dart';

class MailConnectorModel {
  const MailConnectorModel({
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

  factory MailConnectorModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const {};
    return MailConnectorModel(
      id: document.id,
      emailAddress: data['emailAddress'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      provider: _provider(data['provider']),
      status: _status(data['status']),
    );
  }

  MailConnector toDomain() {
    return MailConnector(
      id: id,
      emailAddress: emailAddress,
      displayName: displayName,
      provider: provider,
      status: status,
    );
  }

  static MailConnectorProvider _provider(Object? value) {
    return MailConnectorProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => MailConnectorProvider.microsoftGraph,
    );
  }

  static MailConnectorStatus _status(Object? value) {
    return MailConnectorStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MailConnectorStatus.disconnected,
    );
  }
}
