import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/communication_channel.dart';

class CommunicationChannelModel {
  const CommunicationChannelModel({
    required this.id,
    required this.teamId,
    required this.createdByUid,
    required this.provider,
    required this.kind,
    required this.label,
    required this.address,
    required this.status,
    required this.capabilities,
    this.accountSid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String teamId;
  final String createdByUid;
  final CommunicationProvider provider;
  final CommunicationChannelKind kind;
  final String label;
  final String address;
  final CommunicationChannelStatus status;
  final ChannelCapabilities capabilities;
  final String? accountSid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CommunicationChannelModel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return CommunicationChannelModel(
      id: data['id'] as String? ?? document.id,
      teamId: data['teamId'] as String? ?? '',
      createdByUid: data['createdByUid'] as String? ?? '',
      provider: _provider(data['provider']),
      kind: _kind(data['kind']),
      label: data['label'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: _status(data['status']),
      capabilities: _capabilities(data['capabilities']),
      accountSid: data['accountSid'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  CommunicationChannel toDomain() {
    return CommunicationChannel(
      id: id,
      teamId: TeamId(teamId),
      createdByUid: createdByUid,
      provider: provider,
      kind: kind,
      label: label,
      address: address,
      status: status,
      capabilities: capabilities,
      accountSid: accountSid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static CommunicationProvider _provider(Object? value) {
    return CommunicationProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => CommunicationProvider.twilio,
    );
  }

  static CommunicationChannelKind _kind(Object? value) {
    return CommunicationChannelKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => CommunicationChannelKind.whatsapp,
    );
  }

  static CommunicationChannelStatus _status(Object? value) {
    return CommunicationChannelStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CommunicationChannelStatus.disabled,
    );
  }

  static ChannelCapabilities _capabilities(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const ChannelCapabilities(inbound: true, outbound: false);
    }
    return ChannelCapabilities(
      inbound: value['inbound'] == true,
      outbound: value['outbound'] == true,
    );
  }

  static DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
