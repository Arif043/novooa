import '../../../files/domain/entities/team_id.dart';

enum CommunicationProvider { twilio, microsoftGraph }

enum CommunicationChannelKind { email, whatsapp, sms }

enum CommunicationChannelStatus {
  setupRequired,
  pendingVerification,
  active,
  reauthorizationRequired,
  disabled,
}

class ChannelCapabilities {
  const ChannelCapabilities({required this.inbound, required this.outbound});

  final bool inbound;
  final bool outbound;
}

class CommunicationChannel {
  const CommunicationChannel({
    required this.id,
    required this.teamId,
    required this.createdByUid,
    required this.provider,
    required this.kind,
    required this.label,
    required this.address,
    required this.status,
    required this.capabilities,
    this.connectorId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TeamId teamId;
  final String createdByUid;
  final CommunicationProvider provider;
  final CommunicationChannelKind kind;
  final String label;
  final String address;
  final CommunicationChannelStatus status;
  final ChannelCapabilities capabilities;
  final String? connectorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == CommunicationChannelStatus.active;

  bool get isConnectorBacked => connectorId != null;

  /// Ein Postfach mit abgelaufener Anmeldung; nur erneutes Verbinden hilft.
  bool get needsReconnection =>
      isConnectorBacked &&
      status == CommunicationChannelStatus.reauthorizationRequired;
}
