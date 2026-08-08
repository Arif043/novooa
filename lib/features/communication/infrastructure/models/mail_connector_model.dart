import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/communication_channel.dart';

class MailConnectorModel {
  const MailConnectorModel({
    required this.id,
    required this.teamId,
    required this.createdByUid,
    required this.emailAddress,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String teamId;
  final String createdByUid;
  final String emailAddress;
  final String displayName;
  final String status;

  factory MailConnectorModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const {};
    return MailConnectorModel(
      id: document.id,
      teamId: data['teamId'] as String? ?? '',
      createdByUid: data['createdByUid'] as String? ?? '',
      emailAddress: data['emailAddress'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      status: data['status'] as String? ?? 'disconnected',
    );
  }

  CommunicationChannel toChannel() {
    return CommunicationChannel(
      id: id,
      teamId: TeamId(teamId),
      createdByUid: createdByUid,
      provider: CommunicationProvider.microsoftGraph,
      kind: CommunicationChannelKind.email,
      label: displayName,
      address: emailAddress,
      status: _channelStatus(status),
      capabilities: const ChannelCapabilities(inbound: true, outbound: true),
      connectorId: id,
    );
  }

  CommunicationChannelStatus _channelStatus(String value) {
    return switch (value) {
      'active' => CommunicationChannelStatus.active,
      'reauthorizationRequired' =>
        CommunicationChannelStatus.reauthorizationRequired,
      _ => CommunicationChannelStatus.disabled,
    };
  }
}
