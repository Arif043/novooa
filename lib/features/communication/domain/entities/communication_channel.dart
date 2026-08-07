import '../../../files/domain/entities/team_id.dart';

enum CommunicationProvider { twilio }

enum CommunicationChannelKind { whatsapp, sms }

enum CommunicationChannelStatus {
  setupRequired,
  pendingVerification,
  active,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
